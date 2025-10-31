# auto-setup-windows-dev

"A Powershell script to automatically install and configure essential tools for frontend development on Windows."

## 🚀 Windows11 Frontend Development Setup

This PowerShell script automates the process of installing and updating a predefined list of essential applications on Windows. It intelligently checks if an app is installed, installs it if it's missing, and updates it to the latest version if it's outdated.
It installs essential software, applies system tweaks, and checks your hardware compatibility for modern dev work.

## ✨ Features

📦 Auto-Install: Automatically installs applications that are missing from your system.

⬆️ Auto-Update: Updates existing applications to their latest stable versions.

🛡️ Admin Privileges: Automatically requests Administrator permissions to ensure a seamless installation process.

🤫 Silent Mode: All processes run in the background without requiring user interaction (no more "Next, Next, Finish" clicks).

📊 Final Report: Displays a summary of what was installed, updated, or left untouched at the end.

## 🖥️ Prerequisites

Windows: Windows 10 (version 1809 or later) or Windows 11.
Windows Package Manager (winget): This is usually pre-installed on modern versions of Windows. If not, it can be installed by getting the App Installer from the Microsoft Store.

## 🧰 What it does:

- Installs & updates key tools:

  - Google Chrome
  - Telegram
  - VLC Player
  - VS Code
  - Git
  - Docker
  - RustDesk
  - ShareX
  - Stretchly

## ▶️ How to Run:

### Step 1: Set PowerShell Execution Policy (One-Time Setup)

If you've never run a PowerShell script before, you need to grant permission first.

1.  Search for `PowerShell` in the Start Menu.
2.  Right-click on **Windows PowerShell** and select **Run as administrator**.
3.  Copy and paste the following command into the PowerShell window and press `Enter`:
    ```powershell
    Set-ExecutionPolicy RemoteSigned
    ```
4.  The system will ask for confirmation. Type `Y` and press `Enter`.
5.  You can now close the window. This step is only needed once.

### Step 2: Run the Script

1.  **💾 Save the File:** Place the `auto-setup-windows-dev.ps1` script in a folder of your choice.

2.  **▶️ Execute:** Right-click on the script file and select **Run with PowerShell**.

3.  **🛡️ Grant Permissions:** A UAC (User Account Control) prompt will appear asking for administrator privileges. Click **Yes**.

4.  **☕ Be Patient:** The script will start working. You can monitor its progress in the PowerShell window. Please wait until it's finished and displays the final report.

5.  **📝 Review the Report:** Once done, a final summary will be displayed. You can press any key to close the window.

--.

Of course! Here is a complete `README.md` file in English, formatted with Markdown and appropriate emojis. You can copy and paste this directly into your file.

## ✏️ Customizing the Script

You can easily edit the list of applications to install or update.

1.  Open the `auto-setup-windows-dev.ps1` file with a text editor (like Notepad or VS Code).
2.  Navigate to `--- Section 2: Define the List of Applications ---`.
3.  Edit the `$programs` list following this pattern:

    ```powershell
    $programs = @{
        "AppNameToShowInReport" = "Winget.PackageId"
        # Example:
        "7-Zip"                 = "7zip.7zip"
    }
    ```

**How to find a package ID?**
Open PowerShell or Command Prompt and run the following command:

```
winget search "application name"
```

For example: `winget search "vlc"`

---

## 🛠️ Troubleshooting

**Problem:** I'm getting errors like `Rest API internal error` or source conflicts.

**Solution:** This is often caused by a corrupted `winget` source cache. You can fix it by resetting the sources.

1.  Open **PowerShell as an administrator**.
2.  Run the following command to reset the sources:
    ```powershell
    winget source reset --force
    ```
3.  Then, try running the script again.
