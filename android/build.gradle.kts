// Top-level android/build.gradle.kts

plugins {
    // Google Services plugin, don't apply here, just declare version
    id("com.google.gms.google-services") version "4.3.15" apply false
    // Android Application plugin and Kotlin Android plugin versions
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    //id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Match the Google Services classpath to the plugin version on the classpath (4.3.15)
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory setup (if you really want to keep this)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
