# Script to fix the Kotlin version in ar_flutter_plugin

$pluginDir = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\ar_flutter_plugin-0.7.3\android"
$buildGradlePath = "$pluginDir\build.gradle"

# Check if the plugin directory exists
if (Test-Path $pluginDir) {
    Write-Host "Found AR flutter plugin directory at: $pluginDir"
    
    # Read the build.gradle file
    $buildGradleContent = Get-Content $buildGradlePath -Raw
    
    # Update the Kotlin version from 1.3.50 to 1.5.20
    $newContent = $buildGradleContent -replace "ext\.kotlin_version = '1\.3\.50'", "ext.kotlin_version = '1.5.20'"
    
    # Write the updated content back to the file
    $newContent | Set-Content $buildGradlePath
    
    Write-Host "Successfully updated Kotlin version to 1.5.20 in build.gradle!"
} else {
    Write-Host "AR flutter plugin directory not found: $pluginDir"
} 