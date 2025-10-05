package com.github.frtu.vm.sample.embedded.application

import org.slf4j.LoggerFactory
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
//@ConditionalOnProperty(name = ["application.flink.default"])
@EnableConfigurationProperties(FlinkAppProperties::class)
class FlinkAppConfiguration {
    @Bean
    @ConfigurationProperties(prefix = "application.flink.default")
    fun flinkAppProperties() = FlinkAppProperties()

    private val logger = LoggerFactory.getLogger(this::class.java)
}

