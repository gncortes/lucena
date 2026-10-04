plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase: o google-services.json não é versionado (ver .gitignore).
// Sem ele (CI de PR, forks), o app compila sem a configuração do Firebase.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Assinatura de release: variáveis definidas só pelo CI (ambiente `release` do GitHub).
// Sem elas (build local e CI de PR), o release é assinado com a chave de debug.
val releaseKeystorePath: String? = System.getenv("ANDROID_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }

android {
    namespace = "com.gncortes.lucena"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gncortes.lucena"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    // O multistockfish embute três motores; o app só usa o Stockfish "light" (rede
    // neural pequena embutida, joga offline). Cada motor é carregado só quando é
    // usado, então os outros dois saem do APK sem quebrar nada.
    packaging {
        jniLibs {
            excludes += listOf(
                "**/libmultistockfish_chess.so",
                "**/libmultistockfish_variant.so",
            )
        }
    }

    signingConfigs {
        if (releaseKeystorePath != null) {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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

// O chessground embute 40 conjuntos de peças e os tabuleiros com imagem. O app só oferece
// os conjuntos de licença livre (`PieceStyle`, em lib/domain/models/board_settings.dart) e
// tabuleiros de cor lisa: o resto fica fora do APK, pelo tamanho e pela licença.
val unusedChessgroundAssets = listOf(
    "boards",
    "piece_sets/alpha", "piece_sets/anarcandy", "piece_sets/caliente",
    "piece_sets/california", "piece_sets/cardinal", "piece_sets/chess7",
    "piece_sets/companion", "piece_sets/cooke", "piece_sets/disguised",
    "piece_sets/dubrovny", "piece_sets/fresca", "piece_sets/gioco",
    "piece_sets/governor", "piece_sets/horsey", "piece_sets/icpieces",
    "piece_sets/kiwen-suwi", "piece_sets/kosal", "piece_sets/leipzig",
    "piece_sets/maestro", "piece_sets/monarchy", "piece_sets/reillycraig",
    "piece_sets/riohacha", "piece_sets/shapes", "piece_sets/staunty",
    "piece_sets/symmetric", "piece_sets/tatiana", "piece_sets/totoy",
    "piece_sets/xkcd",
)

tasks.withType<Copy>().matching { it.name.startsWith("copyFlutterAssets") }.configureEach {
    unusedChessgroundAssets.forEach { exclude("**/packages/chessground/assets/$it/**") }
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
