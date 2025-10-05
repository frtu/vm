plugins {
    var kotlin = "1.9.25"
    var springBoot = "3.3.8"

    // Spring
    kotlin("plugin.spring") version kotlin
    id("org.springframework.boot") version springBoot
    id("io.spring.dependency-management") version "1.1.7"

    // Core
    kotlin("jvm") version kotlin
    `java-library`
    `maven-publish`
    // shadow plugin to produce fat JARs
    //    id("com.github.johnrengelman.shadow") version "7.1.2"

    // Application
    application
}

group = "com.github.frtu.vm"
description = "flink-pipeline"
//mainClassName = "com.github.frtu.vm.sample.standalone"

dependencies {
    // frtu libs
    implementation(libs.frtu.utils)
    implementation(libs.frtu.logs)

    // flink
    api(libs.flink.java)
    api(libs.flink.streaming.java)
    api(libs.flink.clients)
    api(libs.flink.connector.base)
    api(libs.flink.connector.kafka)
    api(libs.kafka.clients)

    // spring
    implementation("org.springframework:spring-context")
    implementation("org.springframework.boot:spring-boot-starter")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-configuration-processor")
    testImplementation("org.springframework.boot:spring-boot-starter-test")

    // core
    implementation(libs.jackson.kotlin)
    implementation("ch.qos.logback:logback-classic")

    // base & test
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation(libs.test.runner)
    testImplementation(libs.test.assertions)
    testImplementation(libs.test.mockk)
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
