package com.github.frtu.vm.sample.embedded

import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.Paths
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.api.common.typeutils.base.IntSerializer
import org.apache.flink.core.fs.FileSystem
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.source.FromElementsFunction
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Import
import org.springframework.context.annotation.Primary

@SpringBootTest(classes = [FlinkStreamingSpringBoot::class])
@Import(
    FlinkStreamingSpringBootTestPropertiesConfiguration::class,
    FlinkStreamingSpringBootTestConfiguration::class,
)
class FlinkStreamingSpringBootTest {
    @Autowired
    lateinit var flinkProperties: FlinkProperties

    @Autowired
    lateinit var outputFileName: String

    @Test
    fun localStreamExecution() {
        Thread.sleep(flinkProperties.terminationGracePeriodMs / 2) // fixme
        val outputFileText = String(Files.readAllBytes(Paths.get(outputFileName))).trim { it <= ' ' }
        outputFileText shouldBe "2"
    }
}

@TestConfiguration
class FlinkStreamingSpringBootTestPropertiesConfiguration {
    @Bean
    fun outputFileName(): String = "build/FlinkStreamingSpringBootTest.txt"
}

@TestConfiguration
class FlinkStreamingSpringBootTestConfiguration {
    @Bean("flinkEnvironment")
    @Primary
    fun getFlinkEnvironment(flinkProperties: FlinkProperties) = StreamExecutionEnvironment.createLocalEnvironment()

    @Autowired
    fun populateEnv(flinkEnvironment: StreamExecutionEnvironment, outputFileName: String) {
        flinkEnvironment
            .addSource(
                FromElementsFunction(IntSerializer(), 1, 2, 3),
                TypeInformation.of(Int::class.java)
            )
            .filter { i: Int -> i % 2 == 0 }
            .writeAsText(outputFileName, FileSystem.WriteMode.OVERWRITE)
            .setParallelism(1)
    }
}