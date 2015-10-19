# Docker-Fluentd: the Container to Log Other Containers' Logs

Hosted on [Docker Hub](https://hub.docker.com/r/nritholtz/docker-fluentd)

This container is extremely [ECS](https://aws.amazon.com/documentation/ecs/)-friendly, although it may be used for other environments.

![Docker Stars](https://img.shields.io/docker/stars/nritholtz/docker-fluentd.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/nritholtz/docker-fluentd.svg)
[![](https://badge.imagelayers.io/nritholtz/docker-fluentd:latest.svg)](https://imagelayers.io/?images=nritholtz/docker-fluentd:latest 'Get your own badge on imagelayers.io')

## Supported Environment Variables
| Environment Variable | Purpose                                                   |
| ------------------------- |:---------------------------------------------------------:|
| DEBUG                     | Set to true if local development or non EC2 instance host |
| LOG_ENVIRONMENT          | Logging environment name (e.g. QA or Production). This will be a field in the resulting log entries. Defaults to `development` if not set |
| AWS_REGION               | Set AWS region for CloudWatch. Defaults to `us-east-1` if not set|
| AWS_ACCESS_KEY_ID | [AWS Access Key](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) (Optimally, you can  instead use [Instance Profiles](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) |
|  AWS_SECRET_ACCESS_KEY | [AWS Secret Access Key](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) (Optimally, you can instead use [Instance Profiles](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) |


## What

By running this container with the following command, one can aggregate the logs of Docker containers running on the same host:

```console
docker run -d -e "LOG_ENVIRONMENT=qa" --rm -v /var/lib/docker/containers:/var/lib/docker/containers -v /var/run/docker.sock:/var/run/docker.sock:ro nritholtz/docker-fluentd
```
The container logs will forwarded to [CloudWatch](https://aws.amazon.com/documentation/cloudwatch/), with the `log_group_name` as the Task definition's family, followed by the set `LOG_ENVIRONMENT` environment variable. The `log_stream_name` will be the ECS container's name.

The outputted entries looks exactly like Docker's JSON formatted logs, except it will contain additional fields depending on which environment you are using for starting up your other Docker containers.

**The following scenarios are supported and evaluated in the order that they appear:**

| Environment               | Results                                                   |
| ------------------------- |:---------------------------------------------------------:|
| ECS                       | Log entries will use the running ECS [Task Definition](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html)'s Family and container name for the `container_project` and `container_name` log fields, respectively. In addition, a field `task_definition_version` will be added to the entries as well.|
| Docker Compose            | Log entries will use the running Docker [Compose](https://docs.docker.com/compose/)'s Project and Service for the `container_project` and `container_name` log fields, respectively. |
| Default                   | If container does not fall within either of the previous categories, it will add a field to the log entry for the host's `ip_address`, that will only become populated correctly if you are running this container within an EC2 instance.

*Docker Compose example*
```console
{"log":"2015-10-15T11:44:27Z 54 TID-gomn1ol8g Appworker/Worker/4cab697c-7e67-40ee-a443-b8f52a034183 INFO: completed in: 232.16888 ms\n","stream":"stdout","container_image":"app_web","container_id":"a8c0128c0b47d5a7a5ed702be3c5f57cd62dc73371d5d7743b63a49ac1e09074","container_project":"app","container_service":"worker","time":"2015-10-15T11:44:27+00:00"}
```

## How

`docker-fluentd` uses [Fluentd](https://www.fluentd.org) inside to tail log files that are mounted on `/var/lib/docker/containers/<CONTAINER_ID>/<CONTAINER_ID>-json.log`. It uses the [tail input plugin](https://docs.fluentd.org/articles/in_tail) to tail JSON-formatted log files that each Docker container emits.

Then, Fluentd adds the additional fields using the included `record_transformer` plugin, before writing out to local files using the [file output plugin](https://docs.fluentd.org/articles/out_file). It will also using the [Fluentd CloudWatch Plugin](https://github.com/ryotarai/fluent-plugin-cloudwatch-logs) when sending logs to CloudWatch.

In addition, `docker-fluentd` registers any new containers started from the Docker service on the same host, by using [Docker Gen](https://github.com/jwilder/docker-gen). All of which are managed by a `supervisord` process.

Fluentd has [a lot of plugins](https://www.fluentd.org/plugins) and can probably support your data output destination.