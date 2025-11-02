# =================================================================================
# Script Name:  auto-setup-windows-dev.ps1 (Version 2.1)
# Description:  Performs a hardware check, installs fonts, and sets up apps.
#               MUST BE RUN VIA THE ADMIN SHORTCUT.
# Author:       MohammadReza Jafari
# Version:      2.1
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

# --- OS Info ---
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

# --- CPU Info ---
try {
    $cpu = Get-CimInstance -ClassName Win32_Processor
    Write-Host "`n🧠 --- PROCESSOR (CPU) ---" -ForegroundColor Green
    Write-Host "   Brand & Model:    $($cpu.Name.Trim())" -ForegroundColor White
    Write-Host "   Manufacturer:     $($cpu.Manufacturer)" -ForegroundColor White
    Write-Host "   Cores / Threads:  $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads" -ForegroundColor White
    Write-Host "   Max Clock Speed:  $($cpu.MaxClockSpeed) MHz" -ForegroundColor White
    $cpuCores = $cpu.NumberOfCores
}
catch { Write-Warning "Could not retrieve CPU information." }

# --- RAM Info ---
try {
    $totalRamBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    $totalRamGB = [math]::Round($totalRamBytes / 1GB, 2)
    
    Write-Host "`n💾 --- MEMORY (RAM) ---" -ForegroundColor Green
    Write-Host "   Total Capacity:   $totalRamGB GB" -ForegroundColor White
    
    $memModules = Get-CimInstance -ClassName Win32_PhysicalMemory
    Write-Host "   Modules:" -ForegroundColor White
    foreach ($module in $memModules) {
        $capacityGB = [math]::Round($module.Capacity / 1GB, 2)
        Write-Host "     - $($capacityGB) GB | Speed: $($module.Speed)MHz | Manufacturer: $($module.Manufacturer)" -ForegroundColor Gray
    }
}
catch { Write-Warning "Could not retrieve RAM information." }

# --- GPU Info ---
try {
    $gpus = Get-CimInstance -ClassName Win32_VideoController
    Write-Host "`n🎨 --- GRAPHICS (GPU) ---" -ForegroundColor Green
    foreach ($gpu in $gpus) {
        $vramGB = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }
        Write-Host "   Model:            $($gpu.Name)" -ForegroundColor White
        Write-Host "   VRAM Capacity:    $($vramGB) GB" -ForegroundColor White
    }
}
catch { Write-Warning "Could not retrieve GPU information." }

# --- Storage Info ---
$isSsdPresent = $false
try {
    Write-Host "`n💽 --- STORAGE (Disks) ---" -ForegroundColor Green
    $disks = Get-CimInstance -ClassName Win32_DiskDrive
    foreach ($disk in $disks) {
        $diskType = switch ($disk.MediaType) {
            3 { "HDD" }
            4 { "SSD" }
            default { "Unknown" }
        }
        if ($diskType -eq "SSD") { $isSsdPresent = $true }
        $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
        Write-Host "   - Device: $($disk.Model) ($($diskType))" -ForegroundColor White
        Write-Host "     Capacity: $diskSizeGB GB" -ForegroundColor Gray
    }
    
    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    Write-Host "   Usage:" -ForegroundColor White
    foreach ($ldisk in $logicalDisks) {
        $totalSizeGB = [math]::Round($ldisk.Size / 1GB, 2)
        $freeSpaceGB = [math]::Round($ldisk.FreeSpace / 1GB, 2)
        $percentUsed = if ($totalSizeGB -gt 0) { [math]::Round((($totalSizeGB - $freeSpaceGB) / $totalSizeGB) * 100, 0) } else { 0 }
        
        $barLength = 20
        $filledLength = [math]::Round($barLength * $percentUsed / 100)
        $progressBar = ('#' * $filledLength) + ('-' * ($barLength - $filledLength))

        Write-Host "     Drive $($ldisk.DeviceID) [$progressBar] $percentUsed% Used ($([math]::Round($freeSpaceGB, 1)) GB Free)" -ForegroundColor Gray
    }
}
catch { Write-Warning "Could not retrieve Storage information." }

# --- Ports & Connectivity Info ---
try {
    Write-Host "`n🔌 --- PORTS and CONNECTIVITY ---" -ForegroundColor Green
    
    $netAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter = True"
    Write-Host "   Network Adapters:" -ForegroundColor White
    foreach ($adapter in $netAdapters) {
        $speed = if ($adapter.Speed) { "$([math]::Round($adapter.Speed / 1Gb, 1)) Gbps" } else { "N/A" }
        Write-Host "     - $($adapter.Name) | Speed: $speed" -ForegroundColor Gray
    }

    $usbControllers = Get-CimInstance -ClassName Win32_USBController
    Write-Host "   USB Controllers:" -ForegroundColor White
    foreach ($controller in $usbControllers) {
        Write-Host "     - $($controller.Name)" -ForegroundColor Gray
    }
    Write-Host "     (Note: 'eXtensible Host Controller' usually indicates USB 3.0+ support)" -ForegroundColor DarkGray

}
catch { Write-Warning "Could not retrieve Connectivity information." }

# --- Section 3: Recommendation for Frontend Development ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "     💡 RECOMMENDATION FOR FRONTEND DEVELOPMENT 💡" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$minRam = 16
$minCores = 4

if ($null -ne $totalRamGB) { $isRamSufficient = $totalRamGB -ge $minRam } else { $isRamSufficient = $false }
if ($null -ne $cpuCores) { $isCpuSufficient = $cpuCores -ge $minCores } else { $isCpuSufficient = $false }

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
Read-Host "System report complete. Press Enter to proceed with Font Installation..."

# --- Section 4: Font Installation ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "             🖋️ FONT INSTALLATION 🖋️" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$localFontsDir = Join-Path -Path $scriptPath -ChildPath "fonts"

if (Test-Path $localFontsDir) {
    $fontFiles = Get-ChildItem -Path $localFontsDir -Include *.ttf, *.otf -Recurse
    if ($fontFiles.Count -gt 0) {
        Write-Host "Found $($fontFiles.Count) font file(s) in the 'fonts' directory. Starting installation check..." -ForegroundColor Yellow
        
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        
        foreach ($font in $fontFiles) {
            $installedFontPath = Join-Path -Path $env:windir -ChildPath "Fonts\$($font.Name)"
            if (Test-Path $installedFontPath) {
                Write-Host "  [=] Font '$($font.Name)' is already installed. Skipping." -ForegroundColor Gray
            } else {
                Write-Host "  [+] Installing font '$($font.Name)'..." -ForegroundColor Green
                try {
                    $destination.CopyHere($font.FullName, 0x10)
                    Write-Host "      -> Successfully installed." -ForegroundColor Green
                } catch {
                    Write-Error "      -> Failed to install '$($font.Name)'. Reason: $_"
                }
            }
        }
    } else {
        Write-Warning "The 'fonts' directory exists, but no .ttf or .otf files were found inside."
    }
} else {
    Write-Host "No 'fonts' directory found next to the script. Skipping font installation." -ForegroundColor Yellow
    Write-Host "To install fonts, create a 'fonts' folder and place your .ttf/.otf files inside."
}

Write-Host "`n`n"
Read-Host "Font installation check complete. Press Enter to proceed with Application Setup..."

# --- Section 5: Define Application List ---
$programs = @{
    "AnyDesk"                   = "AnyDesk.AnyDesk"
    "Docker Desktop"            = "Docker.DockerDesktop"
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

# --- Section 6: Prepare for Reporting ---
$report = @{
    installed = [System.Collections.Generic.List[string]]::new()
    updated   = [System.Collections.Generic.List[string]]::new()
    no_action = [System.Collections.Generic.List[string]]::new()
    failed    = [System.Collections.Generic.List[string]]::new()
}

# --- Section 7: Check and Update winget ---
Write-Host "`nChecking for winget..." -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed or not in the system's PATH. Please install 'App Installer' from the Microsoft Store."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Press any key to exit..."
    exit
}
Write-Host "winget found." -ForegroundColor Green
Write-Host "Updating winget sources..." -ForegroundColor Yellow
winget source update | Out-Null

# --- Section 8: Main Loop for App Installation/Update ---
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

# --- Section 9: Display Final Report ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "             📋 APPLICATION SETUP FINAL REPORT 📋" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
if ($report.installed.Count -gt 0) { Write-Host "`n[+] Newly Installed Applications:" -ForegroundColor Green; $report.installed | ForEach-Object { Write-Host "  - $_" } }
if ($report.updated.Count -gt 0) { Write-Host "`n[*] Updated Applications:" -ForegroundColor Yellow; $report.updated | ForEach-Object { Write-Host "  - $_" } }
if ($report.no_action.Count -gt 0) { Write-Host "`n[=] Applications Already Up-to-Date:" -ForegroundColor Gray; $report.no_action | ForEach-Object { Write-Host "  - $_" } }
if ($report.failed.Count -gt 0) { Write-Host "`n[!] Failed Operations:" -ForegroundColor Red; $report.failed | ForEach-Object { Write-Host "  - $_" } }
if ($report.installed.Count -eq 0 -and $report.updated.Count -eq 0 -and $report.failed.Count -eq 0) { Write-Host "`nAll specified applications were already installed and up-to-date." -ForegroundColor Green }
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "Script finished." -ForegroundColor Cyan
Read-Host "Press any key to exit..."