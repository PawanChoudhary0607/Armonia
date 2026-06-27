plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.armonia"

    // Pinned to 36 — do NOT delegate to flutter.compileSdkVersion.
    //
    // Reason 1: The installed Flutter SDK is at D:\flutter. Depending on its
    // version, flutter.compileSdkVersion may resolve to 34 or 35, both of
    // which are below what the current dependency graph requires.
    //
    // Reason 2: supabase_flutter and google_sign_in transitively pull in
    // androidx libraries whose AAR metadata declares minCompileSdk values
    // that have reached 36 with the versions resolved by pub get. The
    // :app:checkDebugAarMetadata task enforces this at build time.
    //
    // AGP 8.9.1 + Gradle 8.11.1 + Kotlin 2.1.0 are all fully compatible
    // with compileSdk 36. No further version changes are required.
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.armonia"
        // flutter.minSdkVersion is left delegated (Flutter sets it to 21,
        // which satisfies supabase_flutter's minimum of API 21).
        minSdk = flutter.minSdkVersion
        // Pinned to 36 to match compileSdk.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
