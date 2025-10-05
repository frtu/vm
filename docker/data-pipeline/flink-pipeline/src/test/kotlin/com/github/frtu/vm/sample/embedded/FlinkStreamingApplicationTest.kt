package com.github.frtu.vm.sample.embedded

import io.kotest.matchers.shouldBe
import java.util.concurrent.ConcurrentLinkedQueue
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.sink.SinkFunction
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Import
import org.springframework.context.annotation.Primary

class CollectorSink : SinkFunction<Int> {
    override fun invoke(value: Int, context: SinkFunction.Context) {
        results.add(value)
        super.invoke(value, context)
    }

    companion object {
        val results = ConcurrentLinkedQueue<Int>()
        fun clear() = results.clear()
    }
}

@SpringBootTest(classes = [FlinkStreamingApplication::class])
@Import(
    FlinkStreamingSpringBootTestConfiguration::class,
)
class FlinkStreamingApplicationTest {
    @Autowired
    lateinit var flinkProperties: FlinkProperties

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