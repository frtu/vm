package com.github.frtu.vm.sample.embedded

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.builder.SpringApplicationBuilder

@SpringBootApplication
class FlinkStreamingApplication {
    companion object {
        @JvmStatic fun main(args: Array<String>) {
            SpringApplicationBuilder(FlinkStreamingApplication::class.java)
                .run(*args)
        }
    }
}
