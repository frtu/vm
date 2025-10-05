package com.github.frtu.vm.sample.embedded

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "flink")
data class FlinkProperties(
    val jobName: String,

    val jobManagerUrl: String,
    val jobManagerPort: Int,

    val remoteEnvJarFiles: List<String>,
    val maxClientRestRequestSizeBytes: Long = 0,
    val terminate: Boolean = false,
    val terminationGracePeriodMs: Long = 0,
)
