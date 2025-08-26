plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.daevis"

    // compileSdk는 Flutter가 관리하는 값 그대로 사용
    compileSdk = flutter.compileSdkVersion

    // ❌ ndkVersion 제거 (NDK 강제 사용 안 함)
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.daevis"

        // ✅ Firebase Core 요구사항: minSdk 23 이상
        minSdk = 23

        // targetSdk, versionCode, versionName 등은 Flutter가 관리
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
