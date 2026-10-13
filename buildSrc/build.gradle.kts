plugins {
    `kotlin-dsl`
    alias(libs.plugins.detekt)
    alias(libs.plugins.diktat)
    alias(libs.plugins.spotless)
}

repositories {
    mavenCentral()
    gradlePluginPortal()
}

dependencies {
    implementation(libs.kotlin.gradlePlugin)
    implementation(libs.detekt.gradlePlugin)
    implementation(libs.spotless.gradlePlugin)
    implementation(libs.diktat.gradlePlugin)
    implementation(libs.dokka.gradlePlugin)
    implementation(libs.kover.gradlePlugin)
}

// buildSrc defines `template.kotlin-library` (the convention plugin every module applies to get
// detekt/diktat/spotless), so it can't apply that plugin to itself — it configures the same three
// tools directly instead, against the repo's shared config, so its own Kotlin source is held to
// the same bar as `app`/`core`. buildSrc is a separate Gradle build, so `rootDir` here is
// `buildSrc/`; the shared config lives one level up, at the real repo root.
val repoRoot = rootDir.parentFile

diktat {
    diktatConfigFile = File(repoRoot, "diktat-analysis.yml")
    inputs {
        // The convention plugin file is a precompiled script plugin, so it's `.gradle.kts`, not
        // `.kt` — diktat's default include pattern misses it unless told to look for `.kts` too.
        include("src/main/**/*.kt", "src/main/**/*.kts")
    }
    reporters {
        plain()
    }
}

spotless {
    kotlin {
        target("src/main/**/*.kt", "src/main/**/*.kts")
        trimTrailingWhitespace()
        leadingTabsToSpaces()
        endWithNewline()
        val delimiter = "^(package|object|import|interface|internal|@file|//startfile|/\\*\\*)"
        licenseHeaderFile(File(repoRoot, "spotless/copyright.kt"), delimiter)
    }
}

detekt {
    baseline = File(repoRoot, "config/detekt/detekt-baseline.xml")
    config.setFrom(File(repoRoot, "config/detekt/detekt.yml"))
    basePath = repoRoot.absolutePath
}

tasks.withType<io.gitlab.arturbosch.detekt.Detekt>().configureEach {
    jvmTarget = "17"
    setSource(files("src/main/kotlin"))
}

tasks.named("check") {
    dependsOn("diktatCheck")
}
