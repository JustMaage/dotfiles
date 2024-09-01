# Function to check if running as admin
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check if Chocolatey is installed
function Test-ChocolateyInstalled {
    return $null -ne (Get-Command choco -ErrorAction SilentlyContinue)
}

# Function to install Chocolatey
function Install-Chocolatey {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Function to install packages using Chocolatey
function Install-Packages {
    choco install -y zoxide oh-my-posh fzf
    choco upgrade -y zoxide oh-my-posh fzf
}

# Function to refresh environment variables
function Update-EnvironmentVariables {
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
}

# Function to copy zen.toml file
function Copy-ZenToml {
    $zenTomlPath = "$PSScriptRoot\.config\ohmyposh\zen.toml"
    if (Test-Path $zenTomlPath) {
        $destinationPath = "$env:POSH_THEMES_PATH\zen.toml"
        Copy-Item -Path $zenTomlPath -Destination $destinationPath -Force
    } else {
        Write-Output "zen.toml not found in the current directory."
        exit
    }
}

# Function to install PSFzf module
function Install-PSFzfModule {
    Install-Module -Name PSFzf -Force -SkipPublisherCheck
}

# Function to update the PowerShell profile
function Update-Profile {
    if (-not (Test-Path -Path $PROFILE)) {
        try {
            New-Item -Path $PROFILE -Type File -Force -ErrorAction Stop
            Write-Output "Profile created at $PROFILE"
        } catch {
            Write-Output "Failed to create the profile: $_"
            exit
        }
    }

    try {
        $profileContent = if (Test-Path -Path $PROFILE) { Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue } else { "" }

        $customProfileStart = "###START CUSTOM PROFILE###"
        $customProfileEnd = "###END CUSTOM PROFILE###"
        $customProfile = @"
$customProfileStart
oh-my-posh init pwsh --config `"`$env:POSH_THEMES_PATH\zen.toml`" | Invoke-Expression
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
Import-Module PSFzf

# Override PSReadLine's history search
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Override default tab completion
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
$customProfileEnd
"@

        if ($profileContent -match $customProfileStart -and $profileContent -match $customProfileEnd) {
            $pattern = "(?s)$customProfileStart.*?$customProfileEnd"
            $profileContent = [regex]::Replace($profileContent, $pattern, $customProfile)
        } else {
            $profileContent += $customProfile
        }

        Set-Content -Path $PROFILE -Value $profileContent
        Write-Output "Profile updated successfully."
    } catch {
        Write-Output "Failed to update the profile: $_"
        exit
    }
}

# Main script logic
if (-not (Test-Administrator)) {
    Write-Output "You must run this script as an Administrator!"
    exit
}

if (-not (Test-ChocolateyInstalled)) {
    Write-Output "Chocolatey is not installed. Installing Chocolatey..."
    Install-Chocolatey
    Write-Output "Chocolatey has been installed. Restart the script now."
    exit
} else {
    Write-Output "Chocolatey is already installed."
}

# Install required packages
Install-Packages

# Refresh environment variables
Update-EnvironmentVariables

# Copy zen.toml file
Copy-ZenToml

# Install PSFzf module
Install-PSFzfModule

# Update the PowerShell profile
Update-Profile

Write-Output "Script completed successfully."

Write-Output "To use the catppuccin theme, follow this guide: https://github.com/catppuccin/windows-terminal"