package com.github.frtu.vm.sample.embedded.application

data class FlinkSourceProperties(
    val topic: String? = null,
    val parallelism: Int? = null,
)