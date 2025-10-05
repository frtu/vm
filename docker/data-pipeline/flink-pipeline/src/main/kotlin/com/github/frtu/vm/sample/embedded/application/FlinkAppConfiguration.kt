package com.github.frtu.vm.sample.embedded.application

import com.github.frtu.vm.sample.standalone.WordCount
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.connector.source.Source
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.sink.PrintSink
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.kafka.KafkaProperties
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
//@ConditionalOnProperty(name = ["application.flink.default"])
@EnableConfigurationProperties(FlinkAppProperties::class)
class FlinkAppConfiguration {
    @Bean
    @ConfigurationProperties(prefix = "application.flink.default")
    fun flinkAppProperties() = FlinkAppProperties()

    @Bean
    fun kafkaSource(
        kafkaProperties: KafkaProperties,
        flinkAppProperties: FlinkAppProperties,
    ): Source<String, *, *> {
        val topic = flinkAppProperties.source?.topic
        logger.debug("TOPIC:{} - KAFKA:{}", topic, kafkaProperties.buildProducerProperties())
        return KafkaSource.builder<String>()
            .setBootstrapServers(kafkaProperties.bootstrapServers.first())
            .setTopics(topic)
            .setStartingOffsets(OffsetsInitializer.earliest())
            .setValueOnlyDeserializer(SimpleStringSchema())
            .build()
    }

    @Bean
    fun registerApplication(
        env: StreamExecutionEnvironment,
        flinkAppProperties: FlinkAppProperties,
        source: Source<String, *, *>,
    ): String {
        val wordCount = WordCount()
        wordCount.defineWorkflow(env, source, 1) { workflow -> workflow.sinkTo(PrintSink()) }
        return "OK"
    }

    private val logger = LoggerFactory.getLogger(this::class.java)
}

