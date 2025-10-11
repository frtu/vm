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

## Runtime

* Bash into container `data-pipeline-jobmanager-1`.
* Go to folder `/workspace/flink-pipeline/build/libs` & check `flink-pipeline.jar` is present
* Run

```bash
/opt/flink/bin/flink run /workspace/flink-pipeline/build/libs/flink-pipeline.jar
```

## Release notes

### 0.0.1-SNAPSHOT - Current version

* Feature list