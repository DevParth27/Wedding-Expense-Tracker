allprojects {
    repositories {
        google()
        mavenCentral()
        // Add JCenter as a fallback repository
        jcenter()
        // Add Maven repository with HTTPS bypass if needed
        maven {
            url = uri("https://jitpack.io")
        }
    }
    
    // Force a consistent version of okio to resolve conflicts
    configurations.all {
        resolutionStrategy {
            force("com.squareup.okio:okio:2.10.0")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
