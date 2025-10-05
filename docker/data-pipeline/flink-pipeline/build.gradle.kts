plugins {
    // Core
    kotlin("jvm") version "1.9.22"
    `java-library`
    `maven-publish`

    // Application
    application
}

group = "com.github.frtu.vm"
description = "flink-pipeline"

dependencies {
    // frtu libs
    implementation(libs.frtu.logs)

    // flink
    api(libs.flink.streaming.java)
    api(libs.flink.clients)
    api(libs.flink.connector.base)
    api(libs.flink.connector.kafka)
    api(libs.kafka.clients)

    // core
    implementation(libs.jackson.kotlin)

    // Core & test
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    testImplementation("org.junit.jupiter:junit-jupiter:5.8.1")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation("io.mockk:mockk:1.13.11")
    testImplementation(libs.kotest.runner)
    testImplementation(libs.kotest.assertions)
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
    withSourcesJar()
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

tasks.withType<JavaCompile>() {
    options.encoding = "UTF-8"
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.withType<Javadoc>() {
    options.encoding = "UTF-8"
}

publishing {
    publications.create<MavenPublication>("maven") {
        from(components["java"])
    }
}

repositories {
    mavenLocal()
    mavenCentral()
    maven {
        url = uri("https://jcenter.bintray.com")
    }

    maven {
        url = uri("https://dl.bintray.com/kotlin/ktor/")
    }

    maven {
        url = uri("https://dl.bintray.com/kotlin/kotlin-eap")
    }

    maven {
        url = uri("https://oss.sonatype.org/content/repositories/snapshots")
    }

    maven {
        url = uri("https://repo.maven.apache.org/maven2/")
    }
}
