# gorush

### Minified Notifier service from gorush.

### BUILD
```
docker-compose -f docker-compose.yml build
```

To get output and without docker build cache
```
DOCKER_BUILDKIT=0 docker-compose -f docker-compose.yml build --no-cache
```

### RUN
```
docker-compose up
```