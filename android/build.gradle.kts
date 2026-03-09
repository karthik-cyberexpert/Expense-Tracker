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

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.property("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    if (getNamespace.invoke(android) == null) {
                        // Hardcode for known problematic plugins
                        val name = project.name
                        val ns = when {
                            name.contains("isar_flutter_libs") -> "dev.isar.isar_flutter_libs"
                            name.contains("path_provider") -> "io.flutter.plugins.pathprovider"
                            else -> "com.${name.replace("-", "_").replace(".", "_")}"
                        }
                        setNamespace.invoke(android, ns)
                    }
                    
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdkVersion.invoke(android, 36)
                } catch (e: Exception) {
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
