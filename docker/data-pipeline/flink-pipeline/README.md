# Project - flink-pipeline

## About

Flink application using Spring Boot

## Configuration

Configure spring application for

* Local env : remove `job-manager-url` & configure `job-parallelism`
* Remote env : configure your `job-manager-url` & `job-manager-port`

```yaml
flink:
  # Job name & file
  job-name: "FlinkStreamingSpringBoot"
  job-parallelism: 2

  # Job manager remote URL
  job-manager-url: "localhost"
  job-manager-port: 28081
  remote-env-jar-files:
    - "build/libs/flink-pipeline.jar"
  max-client-rest-request-size-bytes: 2000000000

  # Host behavior
  terminate: true
  termination-grace-period-ms: 30000
```

## Release notes

### 0.0.1-SNAPSHOT - Current version

* Feature list