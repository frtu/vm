package com.github.frtu.vm.sample.embedded.application

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties
data class FlinkAppProperties(
    var source: FlinkSourceProperties? = null,
)