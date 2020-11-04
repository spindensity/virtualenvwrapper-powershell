#
# VirtualEnvWrapper for PowerShell
#
# Installation script
#

$ModuleName = "VirtualEnvWrapper"
$ModuleVersion = "0.3.0"
$PowerShellPath = Split-Path -Path $PROFILE -Parent
$InstallationPath = Join-Path $PowerShellPath (Join-Path Modules (Join-Path $ModuleName $ModuleVersion))

function Confirm-User($Message) {
    Do {
        $Key = (Read-Host "$Message [Y/n]").ToLower()
    } While ($Key -ne "y" -And $Key -ne "n")

    return $Key
}

Write-Host

$key = Confirm-User "Do you want to install VirtualEnvWrapper for PowerShell?"
if ($key -eq "n") {
    Exit
}

# Test powershell directories in ~\Documents, create it if not exist
if (!(Test-Path $InstallationPath)) {
    Write-Host "Creaate directory : $InstallationPath"
    New-Item -ItemType Directory -Force -Path $InstallationPath
}

Copy-Item VirtualEnvWrapper.psm1 $InstallationPath\VirtualEnvWrapper.psm1
Copy-Item VirtualEnvWrapper.psd1 $InstallationPath\VirtualEnvWrapper.psd1

# If Powershell profile doesn't exist, add it with necessary contents
# Otherwise append contents to existing profile
if (!(Test-Path $PROFILE)) {
    $Key = Confirm-User "The powershell profile is missing, do you want to create it?"
    if ($Key -eq "y")
    {
        Copy-Item Profile.ps1 $PROFILE
    }
} else {
    $From = Get-Content -Path Profile.ps1

    if(!(Select-String -SimpleMatch "VirtualEnvWrapper" -Path $PROFILE))
    {
        Add-Content -Path $PROFILE -Value "`n" -NoNewline
        Add-Content -Path $PROFILE -Value $From -NoNewline
    }
}

Write-Host "Installation done, close this PowerShell and re-open it to activate VirtualEnvWrapper"
Write-Host
