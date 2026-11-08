package com.github.frtu.vm.sample.cdc

import com.github.frtu.vm.sample.cdc.model.Customer
import com.github.frtu.vm.sample.cdc.model.CustomerChangeEvent
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Mapping from the CDC model to the Elasticsearch document of index `customers`.
 */
object CustomerDocuments {
    fun toDocument(customer: Customer, event: CustomerChangeEvent): Map<String, Any?> = linkedMapOf(
        "id" to customer.id,
        "first_name" to customer.fname,
        "last_name" to customer.lname,
        "full_name" to listOfNotNull(customer.fname, customer.lname).joinToString(" ").ifEmpty { null },
        "email" to customer.email,
        "street" to customer.street,
        "zip" to customer.zip,
        "city" to customer.city,
        "phone" to customer.phone,
        "status" to customer.status,
        "registered" to customer.registered?.let { microsToIso(it) },
        // CDC metadata
        "cdc_op" to event.op,
        "cdc_source_ts" to event.source?.tsMs?.let { Instant.ofEpochMilli(it).toString() },
        "cdc_processed_ts" to event.tsMs?.let { Instant.ofEpochMilli(it).toString() },
    )

    /** Debezium MicroTimestamp (µs since epoch) -> ISO-8601, e.g. `2023-02-17T21:36:42Z` */
    fun microsToIso(micros: Long): String =
        Instant.EPOCH.plus(micros, ChronoUnit.MICROS).toString()
}
