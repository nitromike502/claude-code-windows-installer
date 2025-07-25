You are an expert in PowerShell and Windows system administration. Your task is to create a robust and user-friendly installation script for a command-line tool called "Claude Code".

The primary goal is to provide a seamless, "one-click" installation experience for **non-technical users on Windows** who have little to no experience with the command line.

**Project Summary & Core Requirements:**

1.  **Editable Scripts:** The solution must consist of editable, text-based scripts. No compiled executables.
2.  **No Admin for Use:** The user must be able to *run* Claude Code without administrator privileges.
3.  **Admin for Install:** The installation script *is allowed* to request administrator privileges one time to install dependencies and modify the system.
4.  **Target Audience:** Assume the user is unfamiliar with terms like "PATH," "shell," or "dependencies." All communication must be in simple, non-technical language.

---

**I. Project Deliverables**

You will create two files, intended to be delivered to the user in a single `.zip` archive:

1.  **`✅ START HERE - Install Claude Code.bat`**: A simple Batch file. This is the only file the user will interact with. Its sole purpose is to launch the main PowerShell script correctly.
2.  **`src\installer.ps1`**: A PowerShell script containing all the installation logic.

---

**II. The `installer.ps1` Script's Detailed Logic Flow**

This is the main script. It should execute the following steps in order:

1.  **Request Administrator Privileges:**
    *   The script must first check if it's running as an Administrator.
    *   If not, it must display a simple message like "Admin permissions are needed to install system tools. Please click 'Yes' on the prompt." and then re-launch itself with elevated privileges (e.g., using `Start-Process powershell -Verb RunAs`).

2.  **Setup the Environment:**
    *   Once running as admin, set the PowerShell window title to "Claude Code Installer".
    *   Clear the screen and display a friendly welcome message.

3.  **Dependency Check:**
    *   **Check for Git:** Use `Get-Command git -ErrorAction SilentlyContinue` to see if Git is installed and in the PATH.
    *   **Check for Node.js:**
        *   Use `Get-Command node -ErrorAction SilentlyContinue` to see if Node.js is installed.
        *   If it is installed, check its version (`node -v`). The version must be **v20.11.0 or newer**.

4.  **Dependency Installation (if needed):**
    *   For each missing or outdated dependency (Git or Node.js):
        *   Inform the user in simple terms (e.g., "A required tool, Node.js, is missing. We will now install it for you.").
        *   Use `Invoke-WebRequest` to download the official installer. For Node.js, download the latest LTS `.msi` version.
        *   Execute the downloaded installer **silently and unattended** so the user doesn't see another wizard.
            *   Git: `Git-*.exe /VERYSILENT /NORESTART`
            *   Node.js: `msiexec.exe /i node-*.msi /qn /norestart`
        *   **Crucially:** After a silent install, the new program won't be in the current session's PATH. Manually add the default installation directory (e.g., `C:\Program Files\Git\bin`, `C:\Program Files\nodejs`) to the `$env:Path` variable for the *current script session* so that subsequent commands can use it.

5.  **Main Application Installation:**
    *   Once all dependencies are verified, inform the user that you are now installing Claude Code.
    *   Execute the command: `npm install -g @anthropic-ai/claude-code`.
    *   Verify that the command was successful by checking for a zero exit code.

6.  **Windows Explorer Integration (Context Menu):**
    *   Inform the user that you are adding a convenient right-click option.
    *   Programmatically modify the Windows Registry to add an "Open with Claude Code" option to the context menu for folders.
    *   The registry path is: `HKCU:\Software\Classes\Directory\shell\ClaudeCode` and `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`.
    *   The command associated with this menu item should open a new PowerShell terminal window with the working directory set to the folder that was right-clicked. The command should be: `powershell.exe -NoExit -Command "Set-Location -Path '%V'"`
    *   **Icon (Stub):** Add a registry `Icon` string value to the `ClaudeCode` key. For now, use a generic system icon as a placeholder. A good choice is `shell32.dll,3`. We can replace this with a custom `.ico` file path later.

7.  **Final Success Message:**
    *   Display a clear and final success message.
    *   **Do not** create a desktop shortcut.
    *   The message must explain how to use the new context menu item ("Right-click on your project folder and select 'Open with Claude Code'").
    *   It must also prepare the user for the one-time authentication: "The first time you run a command, your browser will open to ask you to log in. This is normal."
    *   Prompt the user to "Press any key to exit."

8.  **Error Handling:**
    *   Wrap major operations (downloads, installations) in `try...catch` blocks.
    *   If an error occurs, display a user-friendly message like "Something went wrong while downloading [Tool]. Please check your internet connection and try again."

---

**III. The `✅ START HERE - Install Claude Code.bat` Script's Content**

This file should contain only one line of code. Its purpose is to launch the PowerShell script in a way that bypasses potential security restrictions on the user's machine.

```batch
@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\src\installer.ps1"
pause
```
