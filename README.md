# Docker-Fluentd: the Container to Log Other Containers' Logs

Hosted on [Docker Hub](https://hub.docker.com/r/nritholtz/docker-fluentd)

## What

By running this container with the following command, one can aggregate the logs of Docker containers running on the same host:

```console
docker run -d -v /var/lib/docker/containers:/var/lib/docker/containers -v /var/run/docker.sock:/var/run/docker.sock:ro nritholtz/docker-fluentd
```

By default, the container logs are stored in /var/log/docker/yyyyMMdd.log inside this logging container. The data is buffered, so you may also see buffer files like /var/log/docker/20141114.b507c71e6fe540eab.log where "b507c71e6fe540eab" is a hash identifier. You can mount that container volume back to host. Also, by modifying `fluent.conf` and rebuilding the Docker image, you can stream up your logs to Elasticsearch, Amazon S3, MongoDB, Treasure Data, etc.

The output log looks exactly like Docker's JSON formatted logs, except it will contain additional fields depending on whether you are running your other container using Docker Compose or through ECS:

Docker Compose example
```console
{"log":"2015-10-15T11:44:27Z 54 TID-gomn1ol8g MegalonWorker/Megalon/4cab697c-7e67-40ee-a443-b8f52a034183 INFO: completed in: 232.16888 ms\n","stream":"stdout","container_image":"megalon_web","container_id":"a8c0128c0b47d5a7a5ed702be3c5f57cd62dc73371d5d7743b63a49ac1e09074","container_project":"megalon","container_service":"worker","time":"2015-10-15T11:44:27+00:00"}
```

## How

`docker-fluentd` uses [Fluentd](https://www.fluentd.org) inside to tail log files that are mounted on `/var/lib/docker/containers/<CONTAINER_ID>/<CONTAINER_ID>-json.log`. It uses the [tail input plugin](https://docs.fluentd.org/articles/in_tail) to tail JSON-formatted log files that each Docker container emits.

Then, Fluentd adds the additional fields using the included `record_transformer` plugin, before writing out to local files using the [file output plugin](https://docs.fluentd.org/articles/out_file).

In addition, `docker-fluentd` registers any new containers started from the Docker service on the same host, by using [Docker Gen](https://github.com/jwilder/docker-gen). All of which are managed by a `supervisord` process.

Fluentd has [a lot of plugins](https://www.fluentd.org/plugins) and can probably support your data output destination.