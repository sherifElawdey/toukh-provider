// Put all Android Gradle outputs on APFS (see toukhAndroidBuildRoot below).
// Using ../build on exFAT causes AppleDouble (`._*`) files that break Gradle deletes and AAPT.
val toukhAndroidBuildRootFile =
    File(
        System.getProperty("user.home"),
        "Library/Caches/toukh_provider_android_build/project_build",
    ).apply { mkdirs() }

// Strip `._*` under both the Flutter legacy build folder (Dart/tool output) and APFS intermediates.
gradle.taskGraph.whenReady {
    val flutterLegacyBuild = rootProject.projectDir.resolve("../build").canonicalFile
    val apfsPath = toukhAndroidBuildRootFile.absolutePath.replace("\"", "\\\"")
    val legacyPath = flutterLegacyBuild.absolutePath.replace("\"", "\\\"")
    rootProject.exec {
        executable = "/bin/bash"
        args(
            "-c",
            "for d in \"$apfsPath\" \"$legacyPath\"; do " +
                "[ -e \"${'$'}d\" ] || continue; " +
                "find \"${'$'}d\" -name '._*' \\( -type f -o -type d \\) -print0 2>/dev/null | xargs -0 rm -rf 2>/dev/null || true; " +
                "done",
        )
        isIgnoreExitValue = true
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val toukhAndroidBuildRoot: Directory =
    objects.directoryProperty().apply { set(toukhAndroidBuildRootFile) }.get()

rootProject.layout.buildDirectory.value(toukhAndroidBuildRoot)

subprojects {
    project.layout.buildDirectory.value(toukhAndroidBuildRoot.dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

tasks.register<Exec>("toukhRepairBuildDirectory") {
    group = "toukh"
    description =
        "Wipe APFS Gradle output cache and legacy Flutter project build/ (fixes sticky AppleDouble / broken intermediates)."
    val cache = toukhAndroidBuildRootFile.absolutePath
    val legacy = rootProject.projectDir.resolve("../build").absolutePath
    commandLine(
        "bash",
        "-lc",
        "rm -rf \"$cache\" \"$legacy\" && mkdir -p \"$cache\" && echo \"[toukh_provider] wiped: $cache and $legacy\"",
    )
}
