# setup-windows-powershell.ps1
# Windows PowerShell environment setup script
# - Installs PSReadLine
# - Enables command history prediction
# - Installs Starship
# - Adds Starship init to PowerShell profile

$ErrorActionPreference = "Stop"

Write-Host "[*] Starting Windows PowerShell setup..." -ForegroundColor Cyan

# ------------------------------------------------------------
# 1. Ensure PowerShell profile directory exists
# ------------------------------------------------------------

$ProfilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ProfileDir = Split-Path $ProfilePath

if (!(Test-Path $ProfileDir)) {
    Write-Host "[*] Creating PowerShell profile directory: $ProfileDir"
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

if (!(Test-Path $ProfilePath)) {
    Write-Host "[*] Creating PowerShell profile: $ProfilePath"
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

# ------------------------------------------------------------
# 2. Install PSReadLine
# ------------------------------------------------------------

Write-Host "[*] Installing PSReadLine..." -ForegroundColor Cyan

try {
    Install-Module -Name PSReadLine -AllowClobber -Force -Scope CurrentUser
    Write-Host "[+] PSReadLine installed successfully." -ForegroundColor Green
}
catch {
    Write-Host "[!] Failed to install PSReadLine." -ForegroundColor Red
    Write-Host $_
}

# ------------------------------------------------------------
# 3. Add PSReadLine prediction option to profile
# ------------------------------------------------------------

$PSReadLineConfig = "Set-PSReadLineOption -PredictionSource History"

$ProfileContent = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue

if ($ProfileContent -notmatch [regex]::Escape($PSReadLineConfig)) {
    Write-Host "[*] Adding PSReadLine prediction config to profile..."
    Add-Content -Path $ProfilePath -Value ""
    Add-Content -Path $ProfilePath -Value "# Enable PSReadLine history prediction"
    Add-Content -Path $ProfilePath -Value $PSReadLineConfig
}
else {
    Write-Host "[=] PSReadLine prediction config already exists."
}

# ------------------------------------------------------------
# 4. Install Starship
# ------------------------------------------------------------

Write-Host "[*] Checking Starship installation..." -ForegroundColor Cyan

$StarshipExists = Get-Command starship -ErrorAction SilentlyContinue

if (-not $StarshipExists) {
    Write-Host "[*] Starship is not installed. Installing..."

    $WingetExists = Get-Command winget -ErrorAction SilentlyContinue

    if ($WingetExists) {
        Write-Host "[*] Installing Starship using winget..."
        winget install --id Starship.Starship -e --accept-source-agreements --accept-package-agreements
    }
    else {
        Write-Host "[!] winget was not found." -ForegroundColor Yellow
        Write-Host "[*] Installing Starship using official Windows installer script..."

        $InstallScript = "$env:TEMP\install-starship.ps1"

        Invoke-WebRequest `
            -Uri "https://starship.rs/install.ps1" `
            -OutFile $InstallScript

        powershell -ExecutionPolicy Bypass -File $InstallScript -Force
    }
}
else {
    Write-Host "[=] Starship is already installed."
}

# ------------------------------------------------------------
# 5. Add Starship init to profile
# ------------------------------------------------------------

$StarshipInit = 'Invoke-Expression (&starship init powershell)'

$ProfileContent = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue

if ($ProfileContent -notmatch [regex]::Escape($StarshipInit)) {
    Write-Host "[*] Adding Starship init to PowerShell profile..."
    Add-Content -Path $ProfilePath -Value ""
    Add-Content -Path $ProfilePath -Value "# Initialize Starship prompt"
    Add-Content -Path $ProfilePath -Value $StarshipInit
}
else {
    Write-Host "[=] Starship init already exists in profile."
}

Write-Host ""
Write-Host "[+] Setup completed!" -ForegroundColor Green
Write-Host "[*] Restart PowerShell or run the following command:"
Write-Host ". `"$ProfilePath`""
