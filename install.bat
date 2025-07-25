@echo off
:: Claude Code Windows Installer - Smart Batch Launcher
:: Automatically detects local vs remote installation mode
:: - Local mode: Uses files from cloned repository
:: - Remote mode: Downloads latest files from GitHub
:: 
:: Usage: 
::   install.bat (from cloned repo or downloaded file)
::   curl -L "...install.bat" -o install.bat && install.bat (single command)
setlocal enabledelayedexpansion

echo ========================================
echo      Claude Code Installer            
echo ========================================
echo.

:: Check if we're running from a cloned repository (local files exist)
set "LOCAL_MODE=false"
set "SCRIPT_DIR=%~dp0"

if exist "%SCRIPT_DIR%src\installer.ps1" (
    if exist "%SCRIPT_DIR%src\config.json" (
        echo Local installation files detected - using cloned repository
        set "LOCAL_MODE=true"
        set "INSTALL_DIR=%SCRIPT_DIR%"
    )
)

if "%LOCAL_MODE%"=="false" (
    echo No local files found - downloading from GitHub...
    echo.
    
    :: Create temporary directory
    set "TEMP_DIR=%TEMP%\ClaudeCodeInstaller_%RANDOM%"
    if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
    if not exist "%TEMP_DIR%\src" mkdir "%TEMP_DIR%\src"
    if not exist "%TEMP_DIR%\assets" mkdir "%TEMP_DIR%\assets"
    
    :: GitHub repository base URL
    set "REPO_BASE=https://raw.githubusercontent.com/nitromike502/claude-code-windows-installer/main"
    
    echo Downloading configuration files...
    curl -L -s -o "%TEMP_DIR%\src\config.json" "%REPO_BASE%/src/config.json"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to download config.json
        goto :cleanup
    )
    
    echo Downloading installer script...
    curl -L -s -o "%TEMP_DIR%\src\installer.ps1" "%REPO_BASE%/src/installer.ps1"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to download installer.ps1
        goto :cleanup
    )
    
    echo Downloading icon file...
    curl -L -s -o "%TEMP_DIR%\assets\claude-color.ico" "%REPO_BASE%/assets/claude-color.ico"
    if !errorlevel! neq 0 (
        echo WARNING: Failed to download icon file, installer will use default icon
    )
    
    echo.
    echo Files downloaded successfully!
    set "INSTALL_DIR=%TEMP_DIR%"
) else (
    echo Using local repository files
)

echo.
echo Starting installation...
echo.

:: Change to installation directory and run installer
cd /d "%INSTALL_DIR%"
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_DIR%\src\installer.ps1"

:cleanup
if "%LOCAL_MODE%"=="false" (
    echo.
    echo Cleaning up temporary files...
    cd /d "%USERPROFILE%"
    rmdir /s /q "%TEMP_DIR%" 2>nul
)

echo.
echo Installation complete!
pause