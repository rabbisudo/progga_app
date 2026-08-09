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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroidProject = {
        if (extensions.findByName("android") != null) {
            val android = extensions.getByName("android")
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // safe bypass
            }
        }
    }

    if (state.executed) {
        configureAndroidProject()
    } else {
        afterEvaluate {
            configureAndroidProject()
        }
    }

    tasks.configureEach {
        if (name.startsWith("compile") && name.endsWith("Kotlin")) {
            try {
                val kotlinOptions = property("kotlinOptions")
                kotlinOptions?.javaClass?.getMethod("setJvmTarget", String::class.java)?.invoke(kotlinOptions, "17")
            } catch (e: Exception) {
                // safe bypass
            }
        }
    }
}
