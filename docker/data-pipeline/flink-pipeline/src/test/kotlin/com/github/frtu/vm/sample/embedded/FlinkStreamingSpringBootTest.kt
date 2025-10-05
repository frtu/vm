package com.github.frtu.vm.sample.embedded

import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.Paths
import java.util.concurrent.ConcurrentLinkedQueue
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.api.common.typeutils.base.IntSerializer
import org.apache.flink.core.fs.FileSystem
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.sink.SinkFunction
import org.apache.flink.streaming.api.functions.source.FromElementsFunction
import org.apache.flink.streaming.connectors.kafka.table.SinkBufferFlushMode
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Import
import org.springframework.context.annotation.Primary

class CollectorSink: SinkFunction<Int> {
    override fun invoke(value: Int, context: SinkFunction.Context) {
        results.add(value)
        super.invoke(value, context)
    }

    companion object {
        val results = ConcurrentLinkedQueue<Int>()
        fun clear() = results.clear()
    }
}

@SpringBootTest(classes = [FlinkStreamingSpringBoot::class])
@Import(
    FlinkStreamingSpringBootTestConfiguration::class,
)
class FlinkStreamingSpringBootTest {
    @Autowired
    lateinit var flinkProperties: FlinkProperties

//    @Autowired
//    lateinit var outputFileName: String

    @Test
    fun localStreamExecution() {
        CollectorSink.clear()
        Thread.sleep(flinkProperties.terminationGracePeriodMs / 2) // fixme
//        val result = String(Files.readAllBytes(Paths.get(outputFileName))).trim { it <= ' ' }
        val output = CollectorSink.results.toList()
        output.size shouldBe 1

        val result = output[0]
        result shouldBe 2
    }
}

@TestConfiguration
class FlinkStreamingSpringBootTestConfiguration {
    @Bean("flinkEnvironment")
    @Primary
    fun getFlinkEnvironment(flinkProperties: FlinkProperties) = StreamExecutionEnvironment.createLocalEnvironment()

    @Autowired
    fun populateEnv(flinkEnvironment: StreamExecutionEnvironment) {
        flinkEnvironment
            .fromElements(1, 2, 3)
            .filter { i: Int -> i % 2 == 0 }
            .addSink(CollectorSink())
            .setParallelism(1)
    }
}