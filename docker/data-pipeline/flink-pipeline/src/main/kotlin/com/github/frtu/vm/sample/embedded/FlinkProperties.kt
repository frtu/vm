package com.github.frtu.vm.sample.embedded

import org.apache.flink.configuration.Configuration
import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "flink")
data class FlinkProperties(
    val jobName: String,

    val jobManagerUrl: String? = null,
    val jobManagerPort: Int? = null,

    val remoteEnvJarFiles: List<String>,
    val maxClientRestRequestSizeBytes: Long = 0,
    val terminate: Boolean = false,
    val terminationGracePeriodMs: Long = 0,
) {
    fun toConfiguration(): Configuration {
        val maxBytes: Long = this.maxClientRestRequestSizeBytes
        val config = Configuration()
        config.setLong("rest.client.max-content-length", maxBytes)
        config.setLong("rest.server.max-content-length", maxBytes)
        config.setString("akka.framesize", maxBytes.toString() + "b")

        // Remote URL
        this.jobManagerUrl?.let {
            config.setString("rest.address", it)
            this.jobManagerPort?.let { config.setInteger("rest.port", it) }
        }
        return config
    }
}
