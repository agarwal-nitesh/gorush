package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"github.com/appleboy/gorush/config"
	"github.com/appleboy/gorush/core"
	"github.com/appleboy/gorush/logx"
	"github.com/appleboy/gorush/notify"
	"github.com/appleboy/gorush/router"
	"github.com/appleboy/gorush/router/graceful"
	"github.com/appleboy/gorush/status"

	"github.com/golang-queue/nats"
	"github.com/golang-queue/nsq"
	"github.com/golang-queue/queue"
	"github.com/golang-queue/redisdb"
)

func main() {
	var (
		configFile string
	)

	router.SetVersion(Version)

	// set default parameters.
	cfg, err := config.LoadConf(configFile)
	if err != nil {
		log.Printf("Load yaml config file error: '%v'", err)

		return
	}

	// Initialize push slots for concurrent iOS pushes
	notify.MaxConcurrentIOSPushes = make(chan struct{}, cfg.Ios.MaxConcurrentPushes)

	if err = logx.InitLog(
		cfg.Log.AccessLevel,
		cfg.Log.AccessLog,
		cfg.Log.ErrorLevel,
		cfg.Log.ErrorLog,
	); err != nil {
		log.Fatalf("can't load log module, error: %v", err)
	}

	if cfg.Core.HTTPProxy != "" {
		err = notify.SetProxy(cfg.Core.HTTPProxy)

		if err != nil {
			logx.LogError.Fatalf("Set Proxy error: %v", err)
		}
	}

	if err = status.InitAppStatus(cfg); err != nil {
		logx.LogError.Fatal(err)
	}

	var w queue.Worker
	switch core.Queue(cfg.Queue.Engine) {
	case core.LocalQueue:
		w = queue.NewConsumer(
			queue.WithQueueSize(int(cfg.Core.QueueNum)),
			queue.WithFn(notify.Run(cfg)),
			queue.WithLogger(logx.QueueLogger()),
		)
	case core.NSQ:
		w = nsq.NewWorker(
			nsq.WithAddr(cfg.Queue.NSQ.Addr),
			nsq.WithTopic(cfg.Queue.NSQ.Topic),
			nsq.WithChannel(cfg.Queue.NSQ.Channel),
			nsq.WithMaxInFlight(int(cfg.Core.WorkerNum)),
			nsq.WithRunFunc(notify.Run(cfg)),
			nsq.WithLogger(logx.QueueLogger()),
		)
	case core.NATS:
		w = nats.NewWorker(
			nats.WithAddr(cfg.Queue.NATS.Addr),
			nats.WithSubj(cfg.Queue.NATS.Subj),
			nats.WithQueue(cfg.Queue.NATS.Queue),
			nats.WithRunFunc(notify.Run(cfg)),
			nats.WithLogger(logx.QueueLogger()),
		)
	case core.Redis:
		w = redisdb.NewWorker(
			redisdb.WithAddr(cfg.Queue.Redis.Addr),
			redisdb.WithChannel(cfg.Queue.Redis.Channel),
			redisdb.WithChannelSize(cfg.Queue.Redis.Size),
			redisdb.WithRunFunc(notify.Run(cfg)),
			redisdb.WithLogger(logx.QueueLogger()),
		)
	default:
		logx.LogError.Fatalf("we don't support queue engine: %s", cfg.Queue.Engine)
	}

	q := queue.NewPool(
		int(cfg.Core.WorkerNum),
		queue.WithWorker(w),
		queue.WithLogger(logx.QueueLogger()),
	)

	g := graceful.NewManager(
		graceful.WithLogger(logx.QueueLogger()),
	)

	g.AddShutdownJob(func() error {
		logx.LogAccess.Info("close the queue system, current queue usage: ", q.Usage())
		// stop queue system and wait job completed
		q.Release()
		// close the connection with storage
		logx.LogAccess.Info("close the storage connection: ", cfg.Stat.Engine)
		if err := status.StatStorage.Close(); err != nil {
			logx.LogError.Fatal("can't close the storage connection: ", err.Error())
		}
		return nil
	})

	if cfg.Ios.Enabled {
		if err = notify.InitAPNSClient(cfg); err != nil {
			logx.LogError.Fatal(err)
		}
	}

	if cfg.Android.Enabled {
		if _, err = notify.InitFCMClient(cfg, cfg.Android.APIKey); err != nil {
			logx.LogError.Fatal(err)
		}
	}

	if cfg.Huawei.Enabled {
		if _, err = notify.InitHMSClient(cfg, cfg.Huawei.AppSecret, cfg.Huawei.AppID); err != nil {
			logx.LogError.Fatal(err)
		}
	}

	g.AddRunningJob(func(ctx context.Context) error {
		return router.RunHTTPServer(ctx, cfg, q)
	})

	<-g.Done()
}

// Version control for notify.
var Version = "No Version Provided"

// handles pinging the endpoint and returns an error if the
// agent is in an unhealthy state.
func pinger(cfg *config.ConfYaml) error {
	transport := &http.Transport{
		Dial: (&net.Dialer{
			Timeout: 5 * time.Second,
		}).Dial,
		TLSHandshakeTimeout: 5 * time.Second,
	}
	client := &http.Client{
		Timeout:   time.Second * 10,
		Transport: transport,
	}
	resp, err := client.Get("http://localhost:" + cfg.Core.Port + cfg.API.HealthURI)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("server returned non-200 status code")
	}
	return nil
}
