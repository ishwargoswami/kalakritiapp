# Script to fix the namespace issue in ar_flutter_plugin

$pluginDir = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\ar_flutter_plugin-0.7.3\android"
$buildGradlePath = "$pluginDir\build.gradle"

# Check if the plugin directory exists
if (Test-Path $pluginDir) {
    Write-Host "Found AR flutter plugin directory at: $pluginDir"
    
    # Get package name from AndroidManifest.xml
    $manifestPath = "$pluginDir\src\main\AndroidManifest.xml"
    $manifestContent = Get-Content $manifestPath -Raw
    
    if ($manifestContent -match 'package="([^"]+)"') {
        $packageName = $matches[1]
        Write-Host "Found package name: $packageName"
        
        # Read the build.gradle file
        $buildGradleContent = Get-Content $buildGradlePath -Raw
        
        # Check if namespace is already defined
        if ($buildGradleContent -notmatch 'namespace\s*=') {
            Write-Host "Adding namespace to build.gradle..."
            
            # Add namespace declaration to the android block
            $newContent = $buildGradleContent -replace '(android\s*\{\s*)',"`$1`n    namespace '$packageName'`n"
            
            # Write the updated content back to the file
            $newContent | Set-Content $buildGradlePath
            
            Write-Host "Successfully added namespace to build.gradle!"
        } else {
            Write-Host "Namespace already defined in build.gradle."
        }
    } else {
        Write-Host "Couldn't find package name in AndroidManifest.xml."
    }
} else {
    Write-Host "AR flutter plugin directory not found: $pluginDir"
} 