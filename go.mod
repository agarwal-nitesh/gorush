module github.com/appleboy/gorush

go 1.15

require (
	github.com/buger/jsonparser v1.1.1
	github.com/gin-contrib/logger v0.2.0
	github.com/gin-gonic/gin v1.7.4
	github.com/go-redis/redis/v8 v8.11.3
	github.com/golang-queue/nats v0.0.4
	github.com/golang-queue/nsq v0.0.6
	github.com/golang-queue/queue v0.0.10
	github.com/golang-queue/redisdb v0.0.5
	github.com/json-iterator/go v1.1.10
	github.com/klauspost/compress v1.12.3 // indirect
	github.com/mattn/go-isatty v0.0.12
	github.com/mitchellh/mapstructure v1.4.1
	github.com/msalihkarakasli/go-hms-push v0.0.0-20210731212030-00e7b986815b
	github.com/prometheus/client_golang v1.10.0
	github.com/rs/zerolog v1.23.0
	github.com/sideshow/apns2 v0.20.0
	github.com/sirupsen/logrus v1.8.1
	github.com/spf13/viper v1.7.1
	github.com/stretchr/testify v1.7.0
	github.com/thoas/stats v0.0.0-20190407194641-965cb2de1678
	golang.org/x/crypto v0.0.0-20210616213533-5ff15b29337e
	golang.org/x/net v0.0.0-20210428140749-89ef3d95e781
	golang.org/x/sync v0.0.0-20210220032951-036812b2e83c
	gopkg.in/yaml.v3 v3.0.0-20200605160147-a5ece683394c // indirect
)

replace github.com/msalihkarakasli/go-hms-push => github.com/spawn2kill/go-hms-push v0.0.0-20211125124117-e20af53b1304
