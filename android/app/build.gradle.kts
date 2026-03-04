import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 릴리스 서명: android/key.properties 파일이 있으면 사용 (없으면 debug 서명)
val keystorePropertiesFile = rootProject.file("key.properties")
val useReleaseSigning = keystorePropertiesFile.exists()
val keystoreProperties = if (useReleaseSigning) {
    Properties().apply { load(FileInputStream(keystorePropertiesFile)) }
} else null

android {
    namespace = "com.todaysunbap.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (useReleaseSigning && keystoreProperties != null) {
            create("release") {
                keyAlias = keystoreProperties!!["keyAlias"] as String
                keyPassword = keystoreProperties!!["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties!!["storeFile"] as String)
                storePassword = keystoreProperties!!["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.todaysunbap.app"
        // Play Console: API 35 이상 타겟팅 요구 (보안·성능)
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (useReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
