package com.github.frtu.vm.sample.cdc

import co.elastic.clients.elasticsearch.core.bulk.DeleteOperation
import co.elastic.clients.elasticsearch.core.bulk.IndexOperation
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.mockk
import org.junit.jupiter.api.Test

internal class CustomerCdcTest {
    private val deserializer = CustomerChangeEventDeserializer()
    private val converter = CustomerBulkOperationConverter("customers")

    // Real message from topic ecommerce_db.inventory.customers (snapshot read)
    private val snapshotEvent = """
        {"before":null,"after":{"id":1001,"fname":"Brandon","lname":"Thomas","email":"brandon.thomas@example.com",
        "street":"29 Oakwood Drive","zip":"90210","city":"Los Angeles","phone":"(800) 555‑2100","status":1,
        "registered":1676669802000000},"source":{"version":"2.5.4.Final","connector":"postgresql","name":"ecommerce_db",
        "ts_ms":1794153432211,"snapshot":"first","db":"ecommerce","sequence":"[null,\"28128464\"]","schema":"inventory",
        "table":"customers","txId":751,"lsn":28128464,"xmin":null},"op":"r","ts_ms":1794153432301,"transaction":null}
    """.trimIndent()

    private val deleteEvent = """
        {"before":{"id":1002,"fname":"Sarah","lname":"Davies","email":"sarah.davies@example.com"},
        "after":null,"source":{"table":"customers","ts_ms":1794153432211},"op":"d","ts_ms":1794153432301}
    """.trimIndent()

    @Test
    fun `Deserialize Debezium snapshot event into model`() {
        val event = deserializer.deserialize(snapshotEvent.toByteArray()).shouldNotBeNull()

        event.op shouldBe "r"
        event.isDelete shouldBe false
        event.source?.table shouldBe "customers"
        val customer = event.current.shouldNotBeNull()
        customer.id shouldBe 1001
        customer.fname shouldBe "Brandon"
        customer.registered shouldBe 1676669802000000
    }

    @Test
    fun `Tombstone and invalid payloads are skipped`() {
        deserializer.deserialize(null).shouldBeNull()
        deserializer.deserialize(ByteArray(0)).shouldBeNull()
        deserializer.deserialize("not json".toByteArray()).shouldBeNull()
    }

    @Test
    fun `Map customer to Elasticsearch document`() {
        val event = deserializer.deserialize(snapshotEvent.toByteArray()).shouldNotBeNull()
        val document = CustomerDocuments.toDocument(event.current!!, event)

        document["id"] shouldBe 1001
        document["full_name"] shouldBe "Brandon Thomas"
        document["registered"] shouldBe "2023-02-17T21:36:42Z"
        document["cdc_op"] shouldBe "r"
    }

    @Test
    fun `Create, update and snapshot events become index operations`() {
        val event = deserializer.deserialize(snapshotEvent.toByteArray()).shouldNotBeNull()
        val operation = converter.apply(event, mockk(relaxed = true))

        operation.shouldBeInstanceOf<IndexOperation<*>>()
        operation.index() shouldBe "customers"
        operation.id() shouldBe "1001"
    }

    @Test
    fun `Delete events become delete operations`() {
        val event = deserializer.deserialize(deleteEvent.toByteArray()).shouldNotBeNull()
        val operation = converter.apply(event, mockk(relaxed = true))

        operation.shouldBeInstanceOf<DeleteOperation>()
        operation.id() shouldBe "1002"
    }
}
