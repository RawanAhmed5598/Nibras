plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.heart_safe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. تفعيل ميزة التبسيط البرمجي (الضرورية لنظام الإشعارات) ✅
        isCoreLibraryDesugaringEnabled = true
        
        // تغيير الإصدار إلى 1.8 لضمان التوافق مع مكتبات البلوتوث والإشعارات
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // توحيد إصدار JVM ليتوافق مع أندرويد
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.heart_safe"
        
        // Nearby Connections و Bluetooth Plus يفضلان minSdk 21 على الأقل ✅
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // الإعدادات الافتراضية للنسخة النهائية
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 2. إضافة المكتبة التي تقوم بعملية التبسيط (Desugaring) في نهاية الملف ✅
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
