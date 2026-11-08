plugins {
    kotlin("jvm") version "2.1.20"
    application
    // shadow plugin to produce the fat job JAR
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

group = "com.github.frtu.sample"
description = "Flink applications for the data-pipeline stack"

val mainClassName = "com.github.frtu.vm.sample.cdc.CustomerCdcToElasticsearchJob"

dependencies {
    // flink core: provided by the cluster (/opt/flink/lib), never bundled in the jar
    compileOnly(libs.flink.streaming.java)
    compileOnly(libs.flink.clients)
    testImplementation(libs.flink.streaming.java)
    testImplementation(libs.flink.clients)

    // flink connectors: not part of the Flink distribution, bundled in the jar
    implementation(libs.flink.connector.base)
    implementation(libs.flink.connector.kafka)
    implementation(libs.flink.connector.elasticsearch8)

    // core
    implementation(libs.jackson.kotlin)
    implementation(kotlin("reflect"))

    // logging: the cluster logs through log4j2, only needed locally
    testRuntimeOnly(libs.log4j.slf4j.impl)
    testRuntimeOnly(libs.log4j.api)
    testRuntimeOnly(libs.log4j.core)

    // test
    testImplementation(platform(libs.junit.bom))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation(libs.test.runner)
    testImplementation(libs.test.assertions)
    testImplementation(libs.test.mockk)
}

// kafka-clients 4.x uses the relocated 'at.yawk.lz4:lz4-java' while Flink uses 'org.lz4:lz4-java'
configurations.all {
    resolutionStrategy.capabilitiesResolution.withCapability("org.lz4:lz4-java") {
        selectHighestVersion()
    }
}

application {
    mainClass.set(mainClassName)
}

// `./gradlew run --args='...'` : local mini-cluster, needs the cluster-provided libs on the classpath
val localRun: Configuration by configurations.creating
dependencies {
    localRun(libs.flink.streaming.java)
    localRun(libs.flink.clients)
    localRun(libs.log4j.slf4j.impl)
    localRun(libs.log4j.api)
    localRun(libs.log4j.core)
}
tasks.named<JavaExec>("run") {
    classpath += localRun
}

java {
    toolchain {
        // cluster image runs java21, bytecode 17 stays compatible
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.shadowJar {
    manifest {
        attributes("Main-Class" to mainClassName)
    }

    dependencies {
        // Provided by the Flink cluster: keep them out even when pulled transitively by connectors
        exclude(dependency("org.apache.flink:flink-core"))
        exclude(dependency("org.apache.flink:flink-core-api"))
        exclude(dependency("org.apache.flink:flink-annotations"))
        exclude(dependency("org.apache.flink:flink-metrics-core"))
        exclude(dependency("org.apache.flink:flink-runtime"))
        exclude(dependency("org.apache.flink:flink-streaming-java"))
        exclude(dependency("org.apache.flink:flink-clients"))
        exclude(dependency("org.apache.flink:flink-java"))
        exclude(dependency("org.apache.flink:flink-rpc-core"))
        exclude(dependency("org.apache.flink:flink-shaded-.*"))
        exclude(dependency("org.apache.flink:flink-table-.*"))
        exclude(dependency("org.apache.flink:flink-file-sink-common"))
        exclude(dependency("org.apache.flink:flink-datastream.*"))
        exclude(dependency("org.slf4j:.*"))
        exclude(dependency("org.apache.logging.log4j:.*"))
        exclude(dependency("com.google.code.findbugs:jsr305"))
    }

    mergeServiceFiles()

    // build/libs/flink-cdc-es.jar, the path expected by scripts/flink.sh submit flink-cdc-es
    archiveClassifier.set("")
    archiveVersion.set("")
}

tasks.build {
    dependsOn(tasks.shadowJar)
}

repositories {
    mavenCentral()
}
