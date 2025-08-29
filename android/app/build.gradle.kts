plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ganixdev.linksan"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.ganixdev.linksan"
        // Flutter requires minimum API 24 (Android 7.0)
        minSdkVersion(24)
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        // ABI filters handled by --split-per-abi flag
    }

    buildTypes {
        release {
            // Aggressive code shrinking and obfuscation for enhanced tree shaking
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Additional optimizations for smaller size and better tree shaking
            buildConfigField("boolean", "LOG_DEBUG", "false")
            buildConfigField("boolean", "LOG_INFO", "false")

            // Enhanced compiler optimizations
            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
            }

            // Signing config for release
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Enable build optimization
    buildFeatures {
        buildConfig = true
        resValues = false
        viewBinding = false
    }
}

flutter {
    source = "../.."
}
