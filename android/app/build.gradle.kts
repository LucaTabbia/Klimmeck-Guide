import com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystoreFile = rootProject.file("key.properties")
val releaseKeystore = Properties().apply {
    if (releaseKeystoreFile.exists()) releaseKeystoreFile.inputStream().use(::load)
}
val hasReleaseKeystore = releaseKeystoreFile.exists()

fun requiredKeystoreProperty(key: String): String =
    requireNotNull(releaseKeystore.getProperty(key)) { "key.properties: $key missing" }

android {
    namespace = "it.lordreavor.klimmeckguide.klimmeck_guide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13599879"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.lordreavor.klimmeckguide.klimmeck_guide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") { dimension = "env" }
        create("prod") { dimension = "env" }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(requiredKeystoreProperty("storeFile"))
                storePassword = requiredKeystoreProperty("storePassword")
                keyAlias = requiredKeystoreProperty("keyAlias")
                keyPassword = requiredKeystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKeystore) "release" else "debug")
        }
    }
}

// D-03a: the debug-keys warning only when a release variant is actually built.
if (!hasReleaseKeystore) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release") }) {
            logger.quiet("WARNING: android/key.properties not found: the release build is signed with the DEBUG keys and cannot be published.")
        }
    }
}

// Phase 5 D-02: google-services.json resta locale (mai in VCS). Senza il file la build
// passa con un warning e a runtime il push resta disabilitato (guard in main()).
googleServices {
    missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Usa l'ultima versione stabile se disponibile
}

flutter {
    source = "../.."
}
