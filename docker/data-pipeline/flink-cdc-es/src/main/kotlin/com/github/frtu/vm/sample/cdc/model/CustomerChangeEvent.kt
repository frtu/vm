package com.github.frtu.vm.sample.cdc.model

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import java.io.Serializable

/**
 * Debezium change event envelope for [Customer]:
 * `{"before": {...}, "after": {...}, "source": {...}, "op": "c|u|d|r", "ts_ms": 123}`
 */
@JsonIgnoreProperties(ignoreUnknown = true)
data class CustomerChangeEvent(
    var before: Customer? = null,
    var after: Customer? = null,
    var source: ChangeSource? = null,
    /** c = create, u = update, d = delete, r = read (snapshot), t = truncate */
    var op: String? = null,
    /** Time Debezium processed the event (ms since epoch) */
    @JsonProperty("ts_ms")
    var tsMs: Long? = null,
) : Serializable {
    val isDelete: Boolean get() = op == OP_DELETE

    /** Row state to index: `after` for c/u/r, `before` for d */
    val current: Customer? get() = if (isDelete) before else after

    companion object {
        const val OP_DELETE = "d"

        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}

@JsonIgnoreProperties(ignoreUnknown = true)
data class ChangeSource(
    var connector: String? = null,
    var db: String? = null,
    var schema: String? = null,
    var table: String? = null,
    /** Time of the change in the database (ms since epoch) */
    @JsonProperty("ts_ms")
    var tsMs: Long? = null,
    var lsn: Long? = null,
) : Serializable {
    companion object {
        @JvmStatic
        private val serialVersionUID: Long = 1
    }
}
