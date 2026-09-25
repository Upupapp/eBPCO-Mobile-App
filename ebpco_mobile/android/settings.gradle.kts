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
    // Pinned below `flutter create`'s AGP 9.1.0 default: AGP 9 enforces
    // Flutter's new "Built-in Kotlin" plugin loading, which file_picker
    // 11.0.3 (and every file_picker release as of 2026-08) hasn't migrated
    // to yet — it still applies its own `org.jetbrains.kotlin.android`
    // plugin the old way, which AGP 9 refuses to compile
    // (GeneratedPluginRegistrant.java: "cannot find symbol FilePickerPlugin",
    // hit live on the Android 16 emulator build). Same fix, same reasoning,
    // as Teresa-Rizal-Mobile-main's own settings.gradle.kts (a different
    // project, same file_picker version, same underlying Gradle conflict).
    // Revisit this pin once file_picker ships a Built-in-Kotlin-compatible
    // release.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
