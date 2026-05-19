plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.handygo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    buildFeatures {
        buildConfig = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Base application ID (will be overridden by flavors)
        applicationId = "com.handygo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // ========== FLAVOR CONFIGURATION ==========
    // This creates two separate apps from the same codebase
    flavorDimensions += "appType"
    
    productFlavors {
        create("client") {
            dimension = "appType"
            applicationId = "com.handygo.client"
            versionNameSuffix = "-client"

            // App name that appears on the phone
            resValue("string", "app_name", "HandyGo")

            // Build config values accessible in Java/Kotlin code
            buildConfigField("String", "APP_TYPE", "\"client\"")
            buildConfigField("String", "API_URL", "\"https://api.handygo.com/v1\"")
            buildConfigField("String", "WEBSOCKET_URL", "\"wss://api.handygo.com/ws\"")
        }

        create("fundi") {
            dimension = "appType"
            applicationId = "com.handygo.fundi"
            versionNameSuffix = "-fundi"

            // App name that appears on the phone
            resValue("string", "app_name", "HandyGo Fundi")

            // Build config values accessible in Java/Kotlin code
            buildConfigField("String", "APP_TYPE", "\"fundi\"")
            buildConfigField("String", "API_URL", "\"https://api.handygo.com/v1\"")
            buildConfigField("String", "WEBSOCKET_URL", "\"wss://api.handygo.com/ws\"")
        }
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
        getByName("debug") {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}