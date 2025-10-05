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
        val config = org.apache.flink.configuration.Configuration()
        val maxBytes: Long = flinkProperties.maxClientRestRequestSizeBytes
        config.setString("rest.address", flinkProperties.jobManagerUrl)
        config.setInteger("rest.port", flinkProperties.jobManagerPort)
        config.setLong("rest.client.max-content-length", maxBytes)
        config.setLong("rest.server.max-content-length", maxBytes)
        config.setString("akka.framesize", maxBytes.toString() + "b")
        return StreamExecutionEnvironment.createRemoteEnvironment(
            flinkProperties.jobManagerUrl,
            flinkProperties.jobManagerPort,
            config,
            *flinkProperties.remoteEnvJarFiles.toTypedArray<String>()
        )
    }

    private val logger = LoggerFactory.getLogger(this::class.java)
}

