package com.github.frtu.vm.sample.embedded.application

import java.io.Serializable
import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties
data class FlinkAppProperties(
    var source: FlinkSourceProperties? = null,
) : Serializable {
    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}