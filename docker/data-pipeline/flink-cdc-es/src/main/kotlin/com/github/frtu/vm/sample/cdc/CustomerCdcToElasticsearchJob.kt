package com.github.frtu.vm.sample.cdc

import co.elastic.clients.elasticsearch.core.bulk.BulkOperationVariant
import co.elastic.clients.elasticsearch.core.bulk.DeleteOperation
import co.elastic.clients.elasticsearch.core.bulk.IndexOperation
import com.github.frtu.vm.sample.cdc.model.CustomerChangeEvent
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.connector.sink2.SinkWriter
import org.apache.flink.connector.base.sink.writer.ElementConverter
import org.apache.flink.connector.elasticsearch.sink.Elasticsearch8AsyncSink
import org.apache.flink.connector.elasticsearch.sink.Elasticsearch8AsyncSinkBuilder
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.util.ParameterTool
import org.apache.http.HttpHost
import org.slf4j.LoggerFactory

/**
 * CDC pipeline : Debezium topic `<prefix>.inventory.customers` (Kafka) -> [CustomerChangeEvent]
 * -> Elasticsearch index `customers` (one document per customer id, deleted on `op=d`).
 *
 * Arguments (all optional, defaults match the docker-compose network):
 * ```
 * --kafka.bootstrap-servers kafka:29092
 * --kafka.topic             ecommerce_db.inventory.customers
 * --kafka.group-id          flink-pipeline-customers
 * --kafka.starting-offsets  earliest | latest
 * --es.host                 elasticsearch
 * --es.port                 9200
 * --es.scheme               http
 * --es.index                customers
 * --es.username / --es.password  (only when ES security is enabled)
 * ```
 */
object CustomerCdcToElasticsearchJob {
    const val JOB_NAME = "customer-cdc-to-elasticsearch"

    @JvmStatic
    fun main(args: Array<String>) {
        val params = ParameterTool.fromArgs(args)
        val env = StreamExecutionEnvironment.getExecutionEnvironment()
        env.config.setGlobalJobParameters(params)
        // At-least-once into ES: flush pending bulk requests on each checkpoint
        env.enableCheckpointing(params.getLong("checkpoint.interval-ms", 10_000))

        val source = kafkaSource(params)
        val sink = elasticsearchSink(params)

        env.fromSource(source, WatermarkStrategy.noWatermarks(), "kafka-customers-cdc")
            .uid("kafka-customers-cdc")
            .filter { it.current != null }
            .name("filter-valid-events")
            .sinkTo(sink)
            .name("elasticsearch-customers")
            .uid("elasticsearch-customers")

        env.execute(params.get("job.name", JOB_NAME))
    }

    fun kafkaSource(params: ParameterTool): KafkaSource<CustomerChangeEvent> {
        val bootstrapServers = params.get("kafka.bootstrap-servers", "kafka:29092")
        val topic = params.get("kafka.topic", "ecommerce_db.inventory.customers")
        val offsets = when (params.get("kafka.starting-offsets", "earliest")) {
            "latest" -> OffsetsInitializer.latest()
            else -> OffsetsInitializer.earliest()
        }
        logger.info("Kafka source: bootstrap={} topic={}", bootstrapServers, topic)
        return KafkaSource.builder<CustomerChangeEvent>()
            .setBootstrapServers(bootstrapServers)
            .setTopics(topic)
            .setGroupId(params.get("kafka.group-id", "flink-pipeline-customers"))
            .setStartingOffsets(offsets)
            .setValueOnlyDeserializer(CustomerChangeEventDeserializer())
            .build()
    }

    fun elasticsearchSink(params: ParameterTool): Elasticsearch8AsyncSink<CustomerChangeEvent> {
        val host = HttpHost(
            params.get("es.host", "elasticsearch"),
            params.getInt("es.port", 9200),
            params.get("es.scheme", "http"),
        )
        val index = params.get("es.index", "customers")
        logger.info("Elasticsearch sink: host={} index={}", host, index)

        val builder = Elasticsearch8AsyncSinkBuilder.builder<CustomerChangeEvent>()
            .setHosts(host)
            .setElementConverter(CustomerBulkOperationConverter(index))
            .setMaxBatchSize(params.getInt("es.max-batch-size", 500))
            .setMaxTimeInBufferMS(params.getLong("es.max-time-in-buffer-ms", 1_000))
        params.get("es.username")?.let { builder.setUsername(it) }
        params.get("es.password")?.let { builder.setPassword(it) }
        return builder.build()
    }

    private val logger = LoggerFactory.getLogger(CustomerCdcToElasticsearchJob::class.java)
}

/**
 * [CustomerChangeEvent] -> ES bulk operation: `index` (upsert by id) for c/u/r, `delete` for d.
 */
class CustomerBulkOperationConverter(
    private val index: String,
) : ElementConverter<CustomerChangeEvent, BulkOperationVariant> {
    override fun apply(event: CustomerChangeEvent, context: SinkWriter.Context): BulkOperationVariant {
        val customer = requireNotNull(event.current) { "event without before/after: $event" }
        val id = customer.id.toString()
        return if (event.isDelete) {
            DeleteOperation.Builder().index(index).id(id).build()
        } else {
            IndexOperation.Builder<Map<String, Any?>>()
                .index(index)
                .id(id)
                .document(CustomerDocuments.toDocument(customer, event))
                .build()
        }
    }

    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}
