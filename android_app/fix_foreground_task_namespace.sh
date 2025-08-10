#!/bin/bash
echo "Fixing flutter_foreground_task namespace issue..."

# Get the user's home directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    GRADLE_FILE="$HOME/.pub-cache/hosted/pub.dev/flutter_foreground_task-3.10.0/android/build.gradle"
else
    # Linux
    GRADLE_FILE="$HOME/.pub-cache/hosted/pub.dev/flutter_foreground_task-3.10.0/android/build.gradle"
fi

echo "Original build.gradle:"
cat "$GRADLE_FILE"

echo ""
echo "Adding namespace to build.gradle..."

cat > "$GRADLE_FILE.new" << EOL
group 'com.pravera.flutter_foreground_task'
version '1.0'

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    namespace 'com.pravera.flutter_foreground_task'
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
    }
}
EOL

mv "$GRADLE_FILE.new" "$GRADLE_FILE"

echo ""
echo "Updated build.gradle:"
cat "$GRADLE_FILE"

echo ""
echo "Fix completed!"
