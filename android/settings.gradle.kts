import java.io.File
import java.nio.file.Files

pluginManagement {
    // When flutter.sdk lives on exFAT, AppleDouble `._*` breaks Gradle deletes under flutter_tools/gradle/build.
    // This block compiles in isolation — keep sanitize logic inlined here (cannot call outer helpers).
    run {
        val lp = File(settings.rootDir, "local.properties")
        if (lp.exists()) {
            val props = java.util.Properties()
            lp.inputStream().use { props.load(it) }
            val flutterSdk = props.getProperty("flutter.sdk") ?: return@run
            val flutterGradleDir = File("$flutterSdk/packages/flutter_tools/gradle").canonicalFile
            if (flutterGradleDir.isDirectory) {
                val fgPath = flutterGradleDir.absolutePath.replace("\"", "\\\"")
                val cacheId = Integer.toHexString(flutterGradleDir.absolutePath.hashCode())
                val cachePath =
                    File(System.getProperty("user.home"), "Library/Caches/toukh_flutter_tools_gradle/$cacheId")
                        .canonicalFile.absolutePath.replace("\"", "\\\"")
                try {
                    ProcessBuilder(
                        "/bin/bash",
                        "-c",
                        "find \"$fgPath/.gradle\" -name '._*' \\( -type f -o -type d \\) -print0 2>/dev/null | xargs -0 rm -rf 2>/dev/null || true; " +
                            "rm -rf \"$fgPath/build\" && mkdir -p \"$cachePath\" && ln -sfn \"$cachePath\" \"$fgPath/build\"",
                    ).redirectErrorStream(true).redirectOutput(ProcessBuilder.Redirect.DISCARD).start().waitFor()
                } catch (_: Exception) {
                    /* non-fatal */
                }
            }
        }
    }

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
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")

// Match root android/build.gradle.kts: Gradle outputs go to APFS under ~/Library/Caches/...
// Flutter CLI still looks for APKs under <project>/build/... — link that path to the same directory.
val toukhFlutterProjectBuildCache =
    File(System.getProperty("user.home"), "Library/Caches/toukh_provider_android_build/project_build")
        .canonicalFile
run {
    toukhFlutterProjectBuildCache.mkdirs()
    val flutterRoot = settings.rootDir.parentFile.canonicalFile
    val buildLink = File(flutterRoot, "build")
    val cachePath = toukhFlutterProjectBuildCache.toPath()
    try {
        if (buildLink.exists()) {
            if (Files.isSymbolicLink(buildLink.toPath())) {
                if (buildLink.canonicalFile == toukhFlutterProjectBuildCache.canonicalFile) {
                    return@run
                }
                buildLink.delete()
            } else if (buildLink.isDirectory) {
                ProcessBuilder(
                    "bash",
                    "-lc",
                    "rm -rf \"${buildLink.absolutePath}\" && ln -sfn \"${toukhFlutterProjectBuildCache.absolutePath}\" \"${buildLink.absolutePath}\"",
                ).redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .redirectError(ProcessBuilder.Redirect.DISCARD)
                    .start()
                    .waitFor()
                return@run
            } else {
                buildLink.delete()
            }
        }
        Files.createSymbolicLink(buildLink.toPath(), cachePath)
    } catch (e: Exception) {
        println("[toukh_provider] Could not link project build/ to Gradle cache: ${e.message}")
    }
}
