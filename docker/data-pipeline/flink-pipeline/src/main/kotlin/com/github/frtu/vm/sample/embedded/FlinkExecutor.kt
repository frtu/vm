package com.github.frtu.vm.sample.embedded

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.slf4j.LoggerFactory
import org.springframework.boot.ExitCodeGenerator
import org.springframework.boot.SpringApplication
import org.springframework.context.ApplicationContext
import org.springframework.context.event.ContextRefreshedEvent
import org.springframework.context.event.EventListener
import org.springframework.core.task.TaskExecutor

class FlinkExecutor(
    private val appCtx: ApplicationContext,
    private val taskExecutor: TaskExecutor,
    private val flinkProperties: FlinkProperties,
    private val flinkEnv: StreamExecutionEnvironment,
) {
    @EventListener
    fun handleContextRefresh(
        event: ContextRefreshedEvent,
    ) = taskExecutor.execute {
        // execute in another thread, so we don't hold it up
        try {
            logger.info("Running flink job {}", flinkProperties.jobName)
            taskExecutor.execute {
                try {
                    flinkEnv.execute(flinkProperties.jobName)
                } catch (e: Exception) {
                    logger.error("Failed to submit flink job", e)
                    conditionallyExitSpringApp(1)
                }
            }
            Thread.sleep(flinkProperties.terminationGracePeriodMs)
            conditionallyExitSpringApp(0)
        } catch (e: InterruptedException) {
            logger.error("Failed to submit flink job", e)
            conditionallyExitSpringApp(1)
        }
    }

    private fun conditionallyExitSpringApp(exitCode: Int) {
        if (flinkProperties.terminate) {
            logger.info("Terminating flink spring application with application code $exitCode")
            System.exit(SpringApplication.exit(appCtx, ExitCodeGenerator { exitCode }))
        }
    }

    private val logger = LoggerFactory.getLogger(this::class.java)
}

