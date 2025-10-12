package com.github.frtu.vm.sample.embedded.application

import java.io.Serializable

data class FlinkSourceProperties(
    val topic: String? = null,
    val parallelism: Int? = null,
) : Serializable {
    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}