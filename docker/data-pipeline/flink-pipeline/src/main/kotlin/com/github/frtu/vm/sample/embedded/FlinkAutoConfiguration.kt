package com.github.frtu.vm.sample.embedded

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.slf4j.LoggerFactory
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.ApplicationContext
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.core.task.SimpleAsyncTaskExecutor
import org.springframework.core.task.TaskExecutor

@Configuration
@EnableConfigurationProperties(FlinkProperties::class)
class FlinkAutoConfiguration {
    @Bean
    fun flinkExecutor(
        appCtx: ApplicationContext, taskExecutor: TaskExecutor,
        flinkProperties: FlinkProperties, flinkEnvironment: StreamExecutionEnvironment,
    ) = FlinkExecutor(appCtx, taskExecutor, flinkProperties, flinkEnvironment)

    @Bean("taskExecutor")
    fun taskExecutor(): TaskExecutor = SimpleAsyncTaskExecutor()

    @Bean("flinkEnvironment")
    fun getFlinkEnvironment(flinkProperties: FlinkProperties): StreamExecutionEnvironment {
        with(flinkProperties) {
            val configuration = this.toConfiguration()
            return if (jobManagerUrl.isNullOrEmpty()) {
                logger.debug(
                    "Creating local env with jobParallelism:{} & configuration:{}",
                    jobParallelism, configuration
                )
                StreamExecutionEnvironment.createLocalEnvironment(this.jobParallelism, configuration)
            } else {
                logger.debug(
                    "Creating remote env to jobmanager:'{}:{}' with configuration:{}",
                    jobManagerUrl, jobManagerPort!!, configuration
                )
                StreamExecutionEnvironment.createRemoteEnvironment(
                    jobManagerUrl, jobManagerPort!!, configuration,
                    // All the JARs to upload
                    *remoteEnvJarFiles.toTypedArray<String>()
                )
            }
        }
    }

    private val logger = LoggerFactory.getLogger(this::class.java)
}

