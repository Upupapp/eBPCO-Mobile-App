pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned below `flutter create`'s AGP 9.0.1 default: AGP 9 enforces
    // Flutter's new "Built-in Kotlin" plugin loading, which file_picker
    // 11.0.3 (and every file_picker release as of 2026-08) hasn't migrated
    // to yet (see https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) —
    // it still applies its own `org.jetbrains.kotlin.android` plugin the
    // old way, which AGP 9 refuses to compile
    // (GeneratedPluginRegistrant.java: "cannot find symbol FilePickerPlugin").
    // AGP 8.11.1 / Kotlin 2.2.20 are the exact floor versions this Flutter
    // release itself requires (below that it warns "support will soon be
    // dropped"; below AGP 8.9.1 some androidx deps refuse to build at all)
    // while staying under AGP 9's Built-in-Kotlin enforcement. Revisit this
    // pin once file_picker ships a Built-in-Kotlin-compatible release.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
