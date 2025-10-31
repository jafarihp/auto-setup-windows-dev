# =================================================================================
# Script Name:  Install-And-Update-Apps.ps1 (Version 1.2 - Added Source Specificity)
# Description:  Checks, installs, and updates applications, specifying the 'winget' source
#               to avoid conflicts and errors.
# Author:       AI Assistant
# Version:      1.2
# =================================================================================

# --- بخش 1: درخواست دسترسی ادمین ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Attempting to re-launch as Administrator..."
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -File `"$PSCommandPath`""
    exit
}

# --- بخش 2: تعریف لیست برنامه‌ها ---
$programs = @{
    "Hiddify Next"      = "Hiddify.HiddifyNext"
    "Google Chrome"     = "Google.Chrome"
    "AnyDesk"           = "AnyDesk.AnyDesk"
    "RustDesk"          = "RustDesk.RustDesk"
    "Telegram Desktop"  = "Telegram.TelegramDesktop"
    "Visual Studio Code"= "Microsoft.VisualStudioCode"
    "Git"               = "Git.Git"
}

# --- بخش 3: آماده‌سازی برای گزارش‌دهی ---
$report = @{
    installed = [System.Collections.Generic.List[string]]::new()
    updated   = [System.Collections.Generic.List[string]]::new()
    no_action = [System.Collections.Generic.List[string]]::new()
}

# --- بخش 4: بررسی و به‌روزرسانی winget ---
# (این بخش بدون تغییر باقی می‌ماند)
Write-Host "Checking for winget..." -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed or not in the system's PATH. Please install 'App Installer' from the Microsoft Store."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Press any key to exit..."
    exit
}
Write-Host "winget found." -ForegroundColor Green
Write-Host "Updating winget sources..." -ForegroundColor Yellow
winget source update | Out-Null

# --- بخش 5: حلقه اصلی برای بررسی، نصب و آپدیت (با تعیین منبع) ---
Write-Host "`n======================================================`n" -ForegroundColor Cyan
Write-Host "Starting Application Health Check..." -ForegroundColor Cyan
Write-Host "`n======================================================`n" -ForegroundColor Cyan

foreach ($program in $programs.GetEnumerator()) {
    $appName = $program.Name
    $appId = $program.Value
    
    Write-Host "Processing: $appName ($appId)" -ForegroundColor Yellow

    # بررسی نصب بودن برنامه از منبع winget
    winget list --id $appId --source winget -e --accept-source-agreements | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  -> Status: Not installed. Attempting to install from 'winget' source..." -ForegroundColor Magenta
        
        # *** تغییر کلیدی: اضافه کردن --source winget ***
        winget install --id $appId --source winget -e --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  -> Result: Successfully installed '$appName'." -ForegroundColor Green
            $report.installed.Add($appName)
        } else {
            Write-Error "  -> Result: Failed to install '$appName'. Exit code: $LASTEXITCODE"
        }
    }
    else {
        Write-Host "  -> Status: Installed. Checking for updates from 'winget' source..." -ForegroundColor Cyan
        
        # *** تغییر کلیدی: اضافه کردن --source winget ***
        $upgradeOutput = winget upgrade --id $appId --source winget -e --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0 -and ($upgradeOutput -notmatch "No applicable update found" -and $upgradeOutput -notmatch "No installed package found matching input criteria")) {
            Write-Host "  -> Result: Successfully updated '$appName'." -ForegroundColor Green
            $report.updated.Add($appName)
        } else {
            Write-Host "  -> Result: '$appName' is already up to date." -ForegroundColor Gray
            $report.no_action.Add($appName)
        }
    }
    Write-Host "------------------------------------------------------"
}


# --- بخش 6: نمایش گزارش نهایی ---
# (این بخش بدون تغییر باقی می‌ماند)
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "                  FINAL REPORT" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
if ($report.installed.Count -gt 0) { Write-Host "`n[+] Newly Installed Applications:" -ForegroundColor Green; $report.installed | ForEach-Object { Write-Host "  - $_" } }
if ($report.updated.Count -gt 0) { Write-Host "`n[*] Updated Applications:" -ForegroundColor Yellow; $report.updated | ForEach-Object { Write-Host "  - $_" } }
if ($report.no_action.Count -gt 0) { Write-Host "`n[=] Applications Already Up-to-Date (No Action Taken):" -ForegroundColor Gray; $report.no_action | ForEach-Object { Write-Host "  - $_" } }
if ($report.installed.Count -eq 0 -and $report.updated.Count -eq 0) { Write-Host "`nAll specified applications were already installed and up-to-date." -ForegroundColor Green }
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "Script finished." -ForegroundColor Cyan
Read-Host "Press any key to exit..."