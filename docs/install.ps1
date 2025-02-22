$ErrorActionPreference = "Stop"

# Constants
$BinaryName = "llogin"
$RepoOwner = "ba3a-g“
$RepoName = "LPU-Wireless-Autologin"
$GithubBase = "https://github.com/$RepoOwner/$RepoName"
$GithubApi = "https://api.github.com/repos/$RepoOwner/$RepoName"

# Helper Functions
function Write-Error-And-Exit($Message) {
    Write-Error $Message
    exit 1
}

function Get-Latest-Version {
    try {
        $response = Invoke-RestMethod -Uri "$GithubApi/releases/latest"
        return $response.tag_name -replace '^v', ''
    }
    catch {
        Write-Error-And-Exit "Failed to fetch latest version: $_"
    }
}

function Get-Platform-Info {
    $arch = if ([System.Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }
    return @{
        OS = "windows"
        Arch = $arch
    }
}

function Install-Binary {
    param (
        [string]$Version
    )

    $platform = Get-Platform-Info
    $binaryName = "$BinaryName-$Version-$($platform.OS)-$($platform.Arch).exe"
    $downloadUrl = "$GithubBase/releases/download/v$Version/$binaryName"
    $tempFile = Join-Path $env:TEMP $binaryName
    $installDir = Join-Path $env:USERPROFILE "bin"
    
    Write-Host "Downloading $BinaryName v$Version for $($platform.OS)-$($platform.Arch)..."

    try {
        # Create install directory if it doesn't exist
        if (!(Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir | Out-Null
        }

        # Download binary
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile

        # Move binary to install location
        $targetPath = Join-Path $installDir $binaryName
        $symlinkPath = Join-Path $installDir "$BinaryName.exe"

        Move-Item -Force $tempFile $targetPath
        
        # Create symlink
        if (Test-Path $symlinkPath) {
            Remove-Item $symlinkPath
        }
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $targetPath | Out-Null

        Write-Host "Installed to: $targetPath"
        Write-Host "Created symlink: $symlinkPath"
        
        # Add to PATH if not already present
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable(
                "Path",
                "$userPath;$installDir",
                "User"
            )
            Write-Host "Added $installDir to User PATH"
        }
    }
    catch {
        Write-Error-And-Exit "Installation failed: $_"
    }
}

function Verify-Installation {
    param (
        [string]$Version
    )
    
    $exePath = Join-Path $env:USERPROFILE "bin\$BinaryName.exe"
    if (Test-Path $exePath) {
        Write-Host "✓ Installation verified: $exePath"
        Write-Host "Version: v$Version"
    }
    else {
        Write-Error-And-Exit "Installation verification failed. Please check your PATH"
    }
}

# Main execution
try {
    $Version = if ($args[0]) { $args[0] } else { Get-Latest-Version }
    Write-Host "Installing $BinaryName v$Version..."
    
    Install-Binary -Version $Version
    Verify-Installation -Version $Version
    Write-Host "Installation completed successfully!"
}
catch {
    Write-Error-And-Exit $_
}