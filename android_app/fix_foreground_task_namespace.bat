@echo off
echo Fixing flutter_foreground_task namespace issue...

set GRADLE_FILE=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_foreground_task-3.10.0\android\build.gradle

echo Original build.gradle:
type "%GRADLE_FILE%"

echo.
echo Adding namespace to build.gradle...

(
echo group 'com.pravera.flutter_foreground_task'
echo version '1.0-SNAPSHOT'
echo.
echo buildscript {
echo     ext.kotlin_version = '1.5.31'
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo.
echo     dependencies {
echo         classpath 'com.android.tools.build:gradle:4.1.3'
echo         classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
echo     }
echo }
echo.
echo rootProject.allprojects {
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo }
echo.
echo apply plugin: 'com.android.library'
echo apply plugin: 'kotlin-android'
echo.
echo android {
echo     namespace 'com.pravera.flutter_foreground_task'
echo     compileSdkVersion 31
echo.
echo     sourceSets {
echo         main.java.srcDirs += 'src/main/kotlin'
echo     }
echo     defaultConfig {
echo         minSdkVersion 21
echo     }
echo }
echo.
echo dependencies {
echo     implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
echo     implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.5.2'
echo }
) > "%GRADLE_FILE%.new"

move /y "%GRADLE_FILE%.new" "%GRADLE_FILE%"

echo.
echo Updated build.gradle:
type "%GRADLE_FILE%"

echo.
echo Fix completed!
