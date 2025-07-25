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
    
    :: Check if curl is available
    curl --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo curl not found, trying PowerShell alternative...
        set "USE_POWERSHELL=true"
    ) else (
        set "USE_POWERSHELL=false"
    )
    
    :: Create temporary directory
    set "TEMP_DIR=%TEMP%\ClaudeCodeInstaller_%RANDOM%"
    if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
    if not exist "%TEMP_DIR%\src" mkdir "%TEMP_DIR%\src"
    if not exist "%TEMP_DIR%\assets" mkdir "%TEMP_DIR%\assets"
    
    :: GitHub repository base URL
    set "REPO_BASE=https://raw.githubusercontent.com/nitromike502/claude-code-windows-installer/main"
    
    echo Downloading configuration files...
    call :DownloadFile "%REPO_BASE%/src/config.json" "%TEMP_DIR%\src\config.json"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to download config.json from GitHub
        echo.
        echo Possible causes:
        echo - Network connectivity issues
        echo - Corporate firewall blocking GitHub
        echo - SSL/TLS certificate issues
        echo.
        echo Please try:
        echo 1. Check internet connection
        echo 2. Download repository manually from GitHub
        echo 3. Run from administrator command prompt
        echo 4. Configure proxy settings if behind corporate firewall
        goto :cleanup
    )
    
    echo Downloading installer script...
    call :DownloadFile "%REPO_BASE%/src/installer.ps1" "%TEMP_DIR%\src\installer.ps1"
    if !errorlevel! neq 0 (
        echo ERROR: Failed to download installer.ps1
        goto :cleanup
    )
    
    echo Downloading icon file...
    call :DownloadFile "%REPO_BASE%/assets/claude-color.ico" "%TEMP_DIR%\assets\claude-color.ico"
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
exit /b 0

:DownloadFile
:: Download file using curl or PowerShell fallback
:: Usage: call :DownloadFile "url" "destination"
set "url=%~1"
set "dest=%~2"

if "%USE_POWERSHELL%"=="true" (
    :: Use PowerShell Invoke-WebRequest
    powershell -Command "try { Invoke-WebRequest -Uri '%url%' -OutFile '%dest%' -UseBasicParsing } catch { exit 1 }"
    exit /b !errorlevel!
) else (
    :: Use curl
    curl -L -s -o "%dest%" "%url%"
    exit /b !errorlevel!
)