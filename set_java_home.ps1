# JDK 17 matches the Android Gradle Plugin / Gradle 8.x toolchain used by this project.
$javaHome = "C:\Program Files\Java\jdk-17"
if (!(Test-Path $javaHome)) {
  Write-Host "JDK 17 not found at $javaHome"
  Write-Host "Install Temurin/Oracle JDK 17, or edit this script to your install path."
  exit 1
}

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
Write-Host "JAVA_HOME set to: $javaHome"
Write-Host "Please RESTART your terminal/IDE for changes to take effect"
