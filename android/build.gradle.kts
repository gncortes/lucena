allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// O plugin sound_effect 0.2.0 compila contra a API 35, mas depende do
// flutter_plugin_android_lifecycle, que exige a 36 de quem o usa: sobe só o
// compileSdk dele (o do app vem do Flutter). Tirar quando o plugin atualizar.
subprojects {
    if (name == "sound_effect") {
        afterEvaluate {
            val android = extensions.findByName("android")
            android
                ?.javaClass
                ?.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                ?.invoke(android, 36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
