# =================================================================================
# Script Name:  auto-setup-windows-dev.ps1 (Version 2.2 - Font Install Last)
# Description:  Performs a hardware check, sets up apps, and finally installs
#               essential Persian fonts. MUST BE RUN VIA ADMIN SHORTCUT.
# Author:       MohammadReza Jafari
# Version:      2.2
# =================================================================================

# --- Section 1: Verify Administrator Privileges ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "FATAL ERROR: This script was not run with Administrator privileges."
    Write-Warning "Please do not run this file directly. Use the special 'Setup Dev Env' Shortcut you created."
    Read-Host "`nPress Enter to exit..."
    exit
}

# --- If we get here, we are running as Admin ---
Write-Host "Successfully running with Administrator privileges." -ForegroundColor Green

# --- Section 2: System Hardware & OS Information ---
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     📊 SYSTEM HARDWARE and OS REPORT 📊" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Gathering system information, please wait..." -ForegroundColor Yellow

try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $lastUpdateDate = try { ($updateSearcher.QueryHistory(0, 1) | Select-Object -First 1).Date } catch { "N/A" }
    
    Write-Host "`n💻 --- OPERATING SYSTEM ---" -ForegroundColor Green
    Write-Host "   OS Name:          $($osInfo.Caption)" -ForegroundColor White
    Write-Host "   Install Date:     $($osInfo.InstallDate | Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host "   Last Update:      $(if ($lastUpdateDate -ne 'N/A') { (Get-Date $lastUpdateDate -Format 'yyyy-MM-dd HH:mm:ss') } else { 'N/A' })" -ForegroundColor White
}
catch { Write-Warning "Could not retrieve OS information." }

try {
    $cpu = Get-CimInstance -ClassName Win32_Processor
    Write-Host "`n🧠 --- PROCESSOR (CPU) ---" -ForegroundColor Green
    Write-Host "   Brand & Model:    $($cpu.Name.Trim())" -ForegroundColor White
    Write-Host "   Cores / Threads:  $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads" -ForegroundColor White
    $cpuCores = $cpu.NumberOfCores
}
catch { Write-Warning "Could not retrieve CPU information." }

try {
    $totalRamBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    $totalRamGB = [math]::Round($totalRamBytes / 1GB, 2)
    
    Write-Host "`n💾 --- MEMORY (RAM) ---" -ForegroundColor Green
    Write-Host "   Total Capacity:   $totalRamGB GB" -ForegroundColor White
}
catch { Write-Warning "Could not retrieve RAM information." }


# --- Section 3: Recommendation for Frontend Development ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "     💡 RECOMMENDATION FOR FRONTEND DEVELOPMENT 💡" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$minRam = 16; $minCores = 4
if ($null -ne $totalRamGB) { $isRamSufficient = $totalRamGB -ge $minRam } else { $isRamSufficient = $false }
if ($null -ne $cpuCores) { $isCpuSufficient = $cpuCores -ge $minCores } else { $isCpuSufficient = $false }
$isSsdPresent = (Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.MediaType -eq 4 }).Count -gt 0

if ($isRamSufficient -and $isSsdPresent -and $isCpuSufficient) {
    Write-Host "`n🎉 Your system is well-equipped for frontend development!" -ForegroundColor Green
    Write-Host "`n💡 Wishing you productive and joyful coding! 🚀" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️ Your system may need upgrades for optimal frontend development." -ForegroundColor Yellow
    $recommendations = @()
    if (-not $isRamSufficient) { $recommendations += "RAM (Recommended: 16GB+)" }
    if (-not $isSsdPresent) { $recommendations += "Storage (Recommended: Use an SSD)" }
    if (-not $isCpuSufficient) { $recommendations += "CPU (Recommended: 4+ Cores)" }
    Write-Host "   Suggested areas for improvement: $($recommendations -join ', ')" -ForegroundColor Gray
}

Write-Host "`n`n"
Read-Host "System report complete. Press Enter to proceed with Application Setup..."

# =================================================================================
#               APPLICATION INSTALLATION AND UPDATE
# =================================================================================

# --- Section 4: Define Application List ---
$programs = @{
    "AnyDesk"                   = "AnyDesk.AnyDesk"
    "Docker Desktop"            = "Docker.DockerDesktop"
    "Everything"                = "voidtools.Everything"
    "Git"                       = "Git.Git"
    "Google Chrome"             = "Google.Chrome"
    "Hiddify"                   = "Hiddify.Hiddify"
    "Internet Download Manager" = "Tonec.InternetDownloadManager"
    "RustDesk"                  = "RustDesk.RustDesk"
    "ShareX"                    = "ShareX.ShareX"
    "Stretchly"                 = "Stretchly.Stretchly"
    "Telegram Desktop"          = "Telegram.TelegramDesktop"
    "Virtual CloneDrive"        = "ElaborateBytes.VirtualCloneDrive"
    "VLC media player"          = "VideoLAN.VLC"
    "VS Code"                   = "Microsoft.VisualStudioCode"
}

# --- Section 5: Prepare for Reporting ---
$report = @{
    installed = [System.Collections.Generic.List[string]]::new()
    updated   = [System.Collections.Generic.List[string]]::new()
    no_action = [System.Collections.Generic.List[string]]::new()
    failed    = [System.Collections.Generic.List[string]]::new()
}

# --- Section 6: Check and Update winget ---
Write-Host "`nChecking for winget..." -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed or not in the system's PATH."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Press any key to exit..."
    exit
}
Write-Host "winget found." -ForegroundColor Green
Write-Host "Updating winget sources..." -ForegroundColor Yellow
winget source update | Out-Null

# --- Section 7: Main Loop for App Installation/Update ---
Write-Host "`n======================================================`n" -ForegroundColor Cyan
Write-Host "         🔧 Starting Application Health Check... 🔧" -ForegroundColor Cyan
Write-Host "`n======================================================`n" -ForegroundColor Cyan

foreach ($program in $programs.GetEnumerator()) {
    $appName = $program.Name
    $appId = $program.Value
    
    Write-Host "Processing: $appName ($appId)" -ForegroundColor Yellow

    winget list --id $appId --source winget -e --accept-source-agreements | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  -> Status: Not installed. Attempting to install..." -ForegroundColor Magenta
        winget install --id $appId --source winget -e --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  -> Result: Successfully installed '$appName'." -ForegroundColor Green
            $report.installed.Add($appName)
        } else {
            Write-Error "  -> Result: Failed to install '$appName'. Exit code: $LASTEXITCODE"
            $report.failed.Add("$appName (Install)")
        }
    } else {
        Write-Host "  -> Status: Installed. Checking for updates..." -ForegroundColor Cyan
        $upgradeOutput = winget upgrade --id $appId --source winget -e --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            if ($upgradeOutput -match "No applicable update found" -or $upgradeOutput -match "No installed package found") {
                Write-Host "  -> Result: '$appName' is already up to date." -ForegroundColor Gray
                $report.no_action.Add($appName)
            } else {
                Write-Host "  -> Result: Successfully updated '$appName'." -ForegroundColor Green
                $report.updated.Add($appName)
            }
        } else {
             Write-Error "  -> Result: Failed to update '$appName'. Exit code: $LASTEXITCODE"
             $report.failed.Add("$appName (Update)")
        }
    }
    Write-Host "------------------------------------------------------"
}

# --- Section 8: Display App Setup Final Report ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "             📋 APPLICATION SETUP FINAL REPORT 📋" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
if ($report.installed.Count -gt 0) { Write-Host "`n[+] Newly Installed Applications:" -ForegroundColor Green; $report.installed | ForEach-Object { Write-Host "  - $_" } }
if ($report.updated.Count -gt 0) { Write-Host "`n[*] Updated Applications:" -ForegroundColor Yellow; $report.updated | ForEach-Object { Write-Host "  - $_" } }
if ($report.no_action.Count -gt 0) { Write-Host "`n[=] Applications Already Up-to-Date:" -ForegroundColor Gray; $report.no_action | ForEach-Object { Write-Host "  - $_" } }
if ($report.failed.Count -gt 0) { Write-Host "`n[!] Failed Operations:" -ForegroundColor Red; $report.failed | ForEach-Object { Write-Host "  - $_" } }
if ($report.installed.Count -eq 0 -and $report.updated.Count -eq 0 -and $report.failed.Count -eq 0) { Write-Host "`nAll specified applications were already installed and up-to-date." -ForegroundColor Green }

Write-Host "`n`n"
Read-Host "Application setup complete. Press Enter to proceed with Font Installation..."

# =================================================================================
#               AUTOMATED FONT INSTALLATION FROM WEB
# =================================================================================

# --- Section 9: Automated Font Installation ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "             🖋️ AUTOMATED FONT INSTALLATION 🖋️" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$fontPackUrl = "https://github.com/Hamid-Najafi/FontPack/archive/refs/heads/master.zip"
$tempDir = Join-Path $env:TEMP "PersianFonts"
$zipFilePath = Join-Path $tempDir "fonts.zip"

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    New-Item -Path $tempDir -ItemType Directory | Out-Null

    Write-Host "Downloading Persian font pack from GitHub..." -ForegroundColor Yellow
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($fontPackUrl, $zipFilePath)
    Write-Host "Download complete." -ForegroundColor Green

    Write-Host "Extracting fonts..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
    Write-Host "Extraction complete." -ForegroundColor Green

    $allFontFiles = Get-ChildItem -Path $tempDir -Include *.ttf, *.otf -Recurse
    if ($allFontFiles.Count -eq 0) {
        throw "No .ttf or .otf files were found in the downloaded package."
    }
    
    Write-Host "Checking for new fonts to install..." -ForegroundColor Yellow
    $fontsToInstall = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    
    foreach ($font in $allFontFiles) {
        $installedFontPath = Join-Path -Path $env:windir -ChildPath "Fonts\$($font.Name)"
        if (-not (Test-Path $installedFontPath)) {
            $fontsToInstall.Add($font)
        }
    }

    if ($fontsToInstall.Count -gt 0) {
        Write-Host "Found $($fontsToInstall.Count) new font(s) to install." -ForegroundColor Cyan
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        
        foreach ($font in $fontsToInstall) {
            Write-Host "  [+] Installing font '$($font.Name)'..." -ForegroundColor Green
            try {
                $destination.CopyHere($font.FullName, 0x10)
            } catch {
                Write-Error "      -> Failed to install '$($font.Name)'. Reason: $_"
            }
        }
        Write-Host "New font installation complete." -ForegroundColor Green
    } else {
        Write-Host "All required fonts are already installed." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred during font installation: $_"
}
finally {
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host "Cleanup complete." -ForegroundColor Green
    }
}

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "Script finished." -ForegroundColor Cyan
Read-Host "Press any key to exit..."