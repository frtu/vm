package com.github.frtu.vm.sample.cdc.model

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import java.io.Serializable

/**
 * Row of table `inventory.customers` (see ../db/init/10-create_inventory.sql),
 * as serialized by Debezium with `JsonConverter` (schemas disabled).
 *
 * Mutable properties with defaults so that Flink treats it as a POJO (no Kryo fallback).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
data class Customer(
    var id: Int = 0,
    var fname: String? = null,
    var lname: String? = null,
    var email: String? = null,
    var street: String? = null,
    var zip: String? = null,
    var city: String? = null,
    var phone: String? = null,
    var status: Int? = null,
    /** Postgres `TIMESTAMP` : Debezium `MicroTimestamp`, microseconds since epoch (UTC) */
    var registered: Long? = null,
) : Serializable {
    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}
