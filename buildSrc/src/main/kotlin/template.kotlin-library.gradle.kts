/*
 * Convention plugin shared by every pure-Kotlin/JVM subproject (`app`, `core`, ...).
 *
 * Bundles the Kotlin/JVM toolchain, the static-analysis stack (detekt/diktat/spotless), Jacoco
 * instrumentation, and the JUnit 5 test stack that used to live inline in the single-module
 * root `build.gradle.kts`. See CLAUDE.md ("Versions are centralized") for the reasoning behind
 * keeping tool versions in `gradle/libs.versions.toml` rather than here.
 */
import io.gitlab.arturbosch.detekt.Detekt
import io.gitlab.arturbosch.detekt.DetektCreateBaselineTask
import io.gitlab.arturbosch.detekt.report.ReportMergeTask
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_2

plugins {
    kotlin("jvm")
    jacoco
    id("io.gitlab.arturbosch.detekt")
    id("com.saveourtool.diktat")
    id("com.diffplug.spotless")
    id("org.jetbrains.dokka")
    id("org.jetbrains.kotlinx.kover")
}

val projectJvmTarget = 17

// Tests run on the toolchain JDK unless `-PtestJdk=<version>` is given. CI's JDK matrix passes it,
// so each leg really runs the tests on its JDK while the bytecode stays targeted at projectJvmTarget.
val testJdk = providers.gradleProperty("testJdk").map { it.toInt() }.orElse(projectJvmTarget)

kotlin {
    jvmToolchain(projectJvmTarget)
    compilerOptions {
        apiVersion.set(KOTLIN_2_2)
        languageVersion.set(KOTLIN_2_2)
    }
}

jacoco {
    toolVersion = "0.8.15"
}

// No shared `kover { reports { verify { ... } } }` rule here: the >=80% line-coverage bound is
// only meaningful for modules with actual business logic to exercise. `core` opts in (see
// core/build.gradle.kts); `app` is bootstrap/wiring code with nothing worth unit-testing, so it
// keeps Kover's reporting (koverXmlReport/koverHtmlReport still work) without the verify gate.

// Every rule in the root diktat-analysis.yml is enabled; the plugin resolves that file from the
// root project, so each module shares one config. Test sources are included too (see `testDirs`
// in the yml for how diktat relaxes rules there).
diktat {
    inputs {
        include("src/main/**/*.kt", "src/test/**/*.kt")
        exclude("**/generated/**")
    }
    // SARIF for GitHub code scanning: each module writes build/reports/diktat/diktat.sarif and the
    // root `mergeDiktatReports` finalizer combines them into build/reports/diktat/diktat-merged.sarif.
    githubActions = true
    // Configuring any reporter drops diktat's implicit console output, so ask for it explicitly.
    reporters {
        plain()
    }
}

// Per-module formatting; the root build script covers files outside modules (root/buildSrc scripts, config).
spotless {
    kotlin {
        target("src/**/*.kt")
        trimTrailingWhitespace()
        leadingTabsToSpaces()
        endWithNewline()
        // `/**` stops the header at a file-level KDoc, which diktat's HEADER_MISSING_IN_NON_SINGLE_CLASS_FILE
        // requires between the license and `package` in files without exactly one class.
        val delimiter = "^(package|object|import|interface|internal|@file|//startfile|/\\*\\*)"
        licenseHeaderFile(rootProject.file("spotless/copyright.kt"), delimiter)
    }
    kotlinGradle {
        target("*.gradle.kts")
        trimTrailingWhitespace()
        leadingTabsToSpaces()
        endWithNewline()
    }
}

detekt {
    // Shared root config/baseline: the baseline is currently empty, so every module is held to
    // the same bar. Split it per module (config/detekt/<module>-baseline.xml) if debt diverges.
    baseline = rootProject.file("config/detekt/detekt-baseline.xml")
    config.setFrom(rootProject.file("config/detekt/detekt.yml"))
    // Repo-relative paths in reports, so SARIF findings map onto files in GitHub code scanning.
    basePath = rootDir.absolutePath
}

// Feed this module's SARIF into the root `detektReportMerge` (build/reports/detekt/merge.sarif).
val detektReportMerge = rootProject.tasks.named<ReportMergeTask>("detektReportMerge")
detektReportMerge.configure {
    input.from(tasks.named<Detekt>("detekt").flatMap { it.sarifReportFile })
}

tasks {
    // `check` (and so `build`) otherwise runs detekt/spotless but not diktat.
    named("check") {
        dependsOn("diktatCheck")
    }

    withType<Test> {
        useJUnitPlatform()
        javaLauncher.set(
            javaToolchains.launcherFor {
                languageVersion.set(testJdk.map { JavaLanguageVersion.of(it) })
            },
        )
        doFirst {
            logger.lifecycle("Running $path on JDK ${javaLauncher.get().metadata.languageVersion}")
        }
        maxParallelForks = 1
        jvmArgs(
            "--add-opens",
            "java.base/jdk.internal.misc=ALL-UNNAMED",
            "--add-exports",
            "java.base/jdk.internal.util=ALL-UNNAMED",
            "--add-exports",
            "java.base/sun.security.action=ALL-UNNAMED",
        )
        testLogging {
            events("passed", "skipped", "failed")
            showStandardStreams = true
        }
        finalizedBy(named("jacocoTestReport"))
    }

    named<JacocoReport>("jacocoTestReport") {
        dependsOn(named("test"))
        reports {
            listOf(html, xml, csv).forEach { it.required.set(true) }
        }
    }

    named<JacocoCoverageVerification>("jacocoTestCoverageVerification") {
        violationRules {
            rule {
                limit {
                    minimum = "0.5".toBigDecimal()
                }
            }
        }
    }

    withType<Detekt>().configureEach {
        description = "Runs over this module's code base."
        parallel = true
        jvmTarget = "$projectJvmTarget"
        setSource(files("src/main/kotlin", "src/test/kotlin"))
        setOf(
            "**/*.kt",
            "**/*.kts",
            ".*/resources/.*",
            ".*/build/.*",
        ).forEach { include(it) }
        reports {
            listOf(xml, html, txt, md, sarif).forEach { it.required.set(true) }
        }
        finalizedBy(detektReportMerge)
    }

    withType<DetektCreateBaselineTask>().configureEach {
        jvmTarget = "$projectJvmTarget"
    }
}

val libs = the<org.gradle.api.artifacts.VersionCatalogsExtension>().named("libs")

dependencies {
    "implementation"(kotlin("stdlib"))

    "testImplementation"(libs.findLibrary("junit-api").get())
    "testImplementation"(libs.findLibrary("junit-params").get())
    "testRuntimeOnly"(libs.findLibrary("junit-engine").get())
    "testRuntimeOnly"("org.junit.platform:junit-platform-launcher")
    "testImplementation"(libs.findLibrary("kotlin-test").get())
    "testImplementation"(libs.findLibrary("assertj").get())
    "testImplementation"(libs.findLibrary("mockk").get())
    "testImplementation"(libs.findLibrary("mockk-bdd").get())
    "testImplementation"(libs.findLibrary("mockito").get())
    "testImplementation"(libs.findLibrary("mockito-kotlin").get())
}
