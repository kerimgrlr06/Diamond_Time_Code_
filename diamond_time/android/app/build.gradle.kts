plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin, Android ve Kotlin pluginlerinden sonra eklenmelidir.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Rapordaki namespace ve compileSdk hatalarını "=" ekleyerek (veya koruyarak) çözeriz.
    namespace = "com.example.diamond_time"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Rapordaki 'coreLibraryDesugaringEnabled' uyarısını bu satır çözer
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.diamond_time"
        // ✅ Namaz vakti paketleri ve modern kütüphaneler için en az API 21 gereklidir
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Rapordaki 'multiDexEnabled' uyarısını standart atama ile çözeriz
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Not: Mağazaya yüklerken kendi imza anahtarınızı oluşturmalısınız.
            signingConfig = signingConfigs.getByName("debug")
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // ✅ Rapordaki sürüm uyarısı için 2.1.4'e yükseltildi
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}