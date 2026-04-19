$javaHome = "C:\Program Files\Java\jdk-25"
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
Write-Host "JAVA_HOME set to: $javaHome"
Write-Host "Please RESTART your terminal/IDE for changes to take effect"