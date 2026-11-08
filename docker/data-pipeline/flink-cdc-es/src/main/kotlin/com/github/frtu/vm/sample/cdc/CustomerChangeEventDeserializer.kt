package com.github.frtu.vm.sample.cdc

import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.github.frtu.vm.sample.cdc.model.CustomerChangeEvent
import org.apache.flink.api.common.serialization.AbstractDeserializationSchema
import org.slf4j.LoggerFactory

/**
 * Kafka value -> [CustomerChangeEvent].
 *
 * Returns `null` (record skipped) for Kafka tombstones (null value sent by Debezium after a delete)
 * and for payloads that can't be parsed, so one bad message doesn't fail the job.
 */
class CustomerChangeEventDeserializer :
    AbstractDeserializationSchema<CustomerChangeEvent>(CustomerChangeEvent::class.java) {

    @Transient
    private var mapper: ObjectMapper? = null

    private fun mapper(): ObjectMapper = mapper ?: jacksonObjectMapper()
        .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
        .also { mapper = it }

    override fun deserialize(message: ByteArray?): CustomerChangeEvent? {
        if (message == null || message.isEmpty()) return null
        return try {
            mapper().readValue(message, CustomerChangeEvent::class.java)
        } catch (e: Exception) {
            logger.warn("Skipping unparsable change event: {}", e.message)
            null
        }
    }

    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
        private val logger = LoggerFactory.getLogger(CustomerChangeEventDeserializer::class.java)
    }
}
