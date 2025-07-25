# Claude Code Windows Installer
# This script installs Claude Code and its dependencies on Windows systems
# 
# Usage:
#   installer.ps1                    # Normal installation
#   installer.ps1 -Force             # Force reinstall of all dependencies
#   installer.ps1 -ForceGit          # Force reinstall Git only
#   installer.ps1 -ForceNode         # Force reinstall Node.js/nvm only

param(
    [switch]$Force,
    [switch]$ForceGit,
    [switch]$ForceNode
)

# Load configuration from config.json
function Get-InstallerConfig {
    $configPath = Join-Path $PSScriptRoot "config.json"
    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }
    
    try {
        $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
        return $configContent
    }
    catch {
        throw "Failed to parse configuration file: $($_.Exception.Message)"
    }
}

# Global configuration variable
$script:Config = Get-InstallerConfig

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to restart script with admin privileges
function Request-AdminPrivileges {
    Write-Host "Admin permissions are needed to install system tools. Please click 'Yes' on the prompt." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`""
    exit
}

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check Node.js version against minimum requirement
function Test-NodeVersion {
    param([string]$Version)
    
    try {
        $versionNumber = $Version -replace 'v', ''
        $versionParts = $versionNumber.Split('.')
        $major = [int]$versionParts[0]
        $minor = [int]$versionParts[1]
        $patch = [int]$versionParts[2]
        
        # Get minimum version from config
        $minVersion = $script:Config.dependencies.nodejs.minimumVersion
        $minParts = $minVersion.Split('.')
        $minMajor = [int]$minParts[0]
        $minMinor = [int]$minParts[1]
        $minPatch = [int]$minParts[2]
        
        # Check if version meets minimum requirement
        if ($major -gt $minMajor) { return $true }
        if ($major -eq $minMajor -and $minor -gt $minMinor) { return $true }
        if ($major -eq $minMajor -and $minor -eq $minMinor -and $patch -ge $minPatch) { return $true }
        
        return $false
    }
    catch {
        return $false
    }
}

# Function to download and install Git
function Install-Git {
    Write-ColoredOutput "A required tool, Git, is missing. We will now install it for you." "Yellow"
    
    try {
        # Detect system architecture
        $architecture = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        Write-ColoredOutput "Detected $architecture Windows system" "Gray"
        
        # Build URL from config template
        $gitConfig = $script:Config.dependencies.git
        $gitUrl = $script:Config.urls.gitBase -replace '{version}', $gitConfig.version -replace '{arch}', $architecture
        $gitInstaller = "$env:TEMP\git-installer.exe"
        
        Write-ColoredOutput "Downloading Git v$($gitConfig.version) for $architecture..." "Cyan"
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        Write-ColoredOutput "Installing Git..." "Cyan"
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        
        # Add Git to PATH for current session
        $gitPath = if ($architecture -eq "64-bit") {
            "C:\Program Files\Git\bin"
        } else {
            "C:\Program Files (x86)\Git\bin"
        }
        
        if (Test-Path $gitPath) {
            $env:Path += ";$gitPath"
        }
        
        Remove-Item $gitInstaller -Force
        Write-ColoredOutput "Git v$($gitConfig.version) installed successfully!" "Green"
    }
    catch {
        throw "Failed to install Git: $($_.Exception.Message)"
    }
}

# Function to download and install Node.js via nvm-windows
function Install-NodeJS {
    Write-ColoredOutput "A required tool, Node.js, is missing or outdated. We will install it using nvm for better version management." "Yellow"
    
    try {
        # First, install nvm-windows
        Write-ColoredOutput "Installing nvm-windows (Node Version Manager)..." "Cyan"
        
        $nvmUrl = $script:Config.urls.nvmWindows
        $nvmInstaller = "$env:TEMP\nvm-setup.exe"
        
        Write-ColoredOutput "Downloading nvm-windows..." "Cyan"
        Invoke-WebRequest -Uri $nvmUrl -OutFile $nvmInstaller -UseBasicParsing
        
        Write-ColoredOutput "Installing nvm-windows..." "Cyan"
        Start-Process -FilePath $nvmInstaller -ArgumentList "/S" -Wait
        
        # Add nvm to PATH for current session
        $nvmPath = "$env:APPDATA\nvm"
        if (Test-Path $nvmPath) {
            $env:Path += ";$nvmPath"
        }
        
        # Refresh environment variables
        $env:NVM_HOME = "$env:APPDATA\nvm"
        $env:NVM_SYMLINK = "$env:ProgramFiles\nodejs"
        
        Remove-Item $nvmInstaller -Force
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 3
        
        # Now install Node.js using version from config
        $nodeConfig = $script:Config.dependencies.nodejs
        $nodeVersion = $nodeConfig.version
        Write-ColoredOutput "Installing Node.js v$nodeVersion using nvm..." "Cyan"
        
        # Use cmd to run nvm commands (nvm-windows is a batch script)
        $nvmExe = "$env:APPDATA\nvm\nvm.exe"
        if (-not (Test-Path $nvmExe)) {
            # Fallback path
            $nvmExe = "C:\ProgramData\nvm\nvm.exe"
        }
        
        if (Test-Path $nvmExe) {
            # Install Node.js from config
            Start-Process -FilePath $nvmExe -ArgumentList "install", $nodeVersion -Wait -NoNewWindow
            
            # Set as default version
            Start-Process -FilePath $nvmExe -ArgumentList "use", $nodeVersion -Wait -NoNewWindow
            
            # Add Node.js to PATH for current session
            $nodeSymlink = "$env:ProgramFiles\nodejs"
            if (Test-Path $nodeSymlink) {
                $env:Path += ";$nodeSymlink"
            }
        } else {
            throw "nvm installation failed - executable not found"
        }
        
        Write-ColoredOutput "Node.js v$nodeVersion installed successfully via nvm!" "Green"
        Write-ColoredOutput "You can now use 'nvm list' and 'nvm use <version>' to manage Node.js versions." "Gray"
    }
    catch {
        throw "Failed to install Node.js via nvm: $($_.Exception.Message)"
    }
}

# Function to install Claude Code
function Install-ClaudeCode {
    Write-ColoredOutput "Installing Claude Code..." "Cyan"
    
    try {
        $result = npm install -g @anthropic-ai/claude-code 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed with exit code $LASTEXITCODE"
        }
        Write-ColoredOutput "Claude Code installed successfully!" "Green"
    }
    catch {
        throw "Failed to install Claude Code: $($_.Exception.Message)"
    }
}

# Function to add Windows Explorer context menu
function Add-ContextMenu {
    Write-ColoredOutput "Adding convenient right-click option to Windows Explorer..." "Cyan"
    
    try {
        $contextConfig = $script:Config.installer
        
        # Registry paths for folder context menu
        $folderPath = "HKCU:\Software\Classes\Directory\shell\ClaudeCode"
        $folderCommandPath = "$folderPath\command"
        
        # Registry paths for folder background context menu
        $backgroundPath = "HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode"
        $backgroundCommandPath = "$backgroundPath\command"
        
        # Create registry keys for folder context menu
        New-Item -Path $folderPath -Force | Out-Null
        New-Item -Path $folderCommandPath -Force | Out-Null
        
        # Set values for folder context menu
        Set-ItemProperty -Path $folderPath -Name "(Default)" -Value $contextConfig.contextMenuText
        Set-ItemProperty -Path $folderPath -Name "Icon" -Value $contextConfig.contextMenuIcon
        Set-ItemProperty -Path $folderCommandPath -Name "(Default)" -Value 'powershell.exe -NoExit -Command "Set-Location -Path ''%V''; claude-code"'
        
        # Create registry keys for folder background context menu
        New-Item -Path $backgroundPath -Force | Out-Null
        New-Item -Path $backgroundCommandPath -Force | Out-Null
        
        # Set values for folder background context menu
        Set-ItemProperty -Path $backgroundPath -Name "(Default)" -Value $contextConfig.contextMenuText
        Set-ItemProperty -Path $backgroundPath -Name "Icon" -Value $contextConfig.contextMenuIcon
        Set-ItemProperty -Path $backgroundCommandPath -Name "(Default)" -Value 'powershell.exe -NoExit -Command "Set-Location -Path ''%V''; claude-code"'
        
        Write-ColoredOutput "Context menu added successfully!" "Green"
    }
    catch {
        throw "Failed to add context menu: $($_.Exception.Message)"
    }
}

# Main installation logic
try {
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Request-AdminPrivileges
        return
    }
    
    # Setup environment
    $Host.UI.RawUI.WindowTitle = "Claude Code Installer"
    Clear-Host
    
    Write-ColoredOutput "========================================" "Magenta"
    Write-ColoredOutput "    Welcome to Claude Code Installer   " "Magenta"
    Write-ColoredOutput "========================================" "Magenta"
    
    # Display force flags if active
    if ($Force -or $ForceGit -or $ForceNode) {
        Write-ColoredOutput ""
        $forceFlags = @()
        if ($Force) { $forceFlags += "Force (all dependencies)" }
        if ($ForceGit) { $forceFlags += "ForceGit" }
        if ($ForceNode) { $forceFlags += "ForceNode" }
        Write-ColoredOutput "Active flags: $($forceFlags -join ', ')" "Yellow"
    }
    
    Write-ColoredOutput ""
    
    # Check dependencies
    Write-ColoredOutput "Checking system requirements..." "Cyan"
    
    $gitExists = Get-Command git -ErrorAction SilentlyContinue
    $nodeExists = Get-Command node -ErrorAction SilentlyContinue
    $nvmExists = Get-Command nvm -ErrorAction SilentlyContinue
    $nodeVersionOk = $false
    
    if ($nodeExists) {
        $nodeVersion = node -v
        $nodeVersionOk = Test-NodeVersion $nodeVersion
        if (-not $nodeVersionOk) {
            $minVersion = $script:Config.dependencies.nodejs.minimumVersion
            Write-ColoredOutput "Node.js version $nodeVersion found, but v$minVersion or newer is required." "Yellow"
        }
    } elseif ($nvmExists) {
        # Check if nvm has any Node.js versions installed
        try {
            $nvmList = nvm list 2>$null
            $minMajor = $script:Config.dependencies.nodejs.minimumVersion.Split('.')[0]
            if ($nvmList -match "$minMajor\.\d+\.\d+") {
                $nodeVersionOk = $true
                Write-ColoredOutput "Node.js v$minMajor.x found via nvm." "Green"
            }
        } catch {
            # nvm exists but no suitable Node.js version
        }
    }
    
    # Install missing dependencies (with force flags)
    if (-not $gitExists -or $Force -or $ForceGit) {
        if ($gitExists -and ($Force -or $ForceGit)) {
            Write-ColoredOutput "Force flag detected - reinstalling Git..." "Yellow"
        }
        Install-Git
    } else {
        Write-ColoredOutput "Git is already installed." "Green"
    }
    
    if (-not $nodeExists -or -not $nodeVersionOk -or $Force -or $ForceNode) {
        if (($nodeExists -or $nvmExists) -and ($Force -or $ForceNode)) {
            Write-ColoredOutput "Force flag detected - reinstalling Node.js/nvm..." "Yellow"
        }
        
        if ($nvmExists -and -not $nodeVersionOk -and -not $Force -and -not $ForceNode) {
            $nodeVersion = $script:Config.dependencies.nodejs.version
            Write-ColoredOutput "nvm is installed but needs Node.js v$nodeVersion. Installing via nvm..." "Yellow"
            # Just install Node.js via existing nvm
            try {
                $nvmExe = Get-Command nvm -ErrorAction SilentlyContinue
                if ($nvmExe) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "nvm", "install", $nodeVersion -Wait -NoNewWindow
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "nvm", "use", $nodeVersion -Wait -NoNewWindow
                    Write-ColoredOutput "Node.js v$nodeVersion installed via existing nvm!" "Green"
                } else {
                    Install-NodeJS
                }
            } catch {
                Install-NodeJS
            }
        } else {
            Install-NodeJS
        }
    } else {
        Write-ColoredOutput "Node.js is already installed and up to date." "Green"
    }
    
    # Install Claude Code
    Write-ColoredOutput ""
    Install-ClaudeCode
    
    # Add context menu integration
    Write-ColoredOutput ""
    Add-ContextMenu
    
    # Success message
    Write-ColoredOutput ""
    Write-ColoredOutput "========================================" "Green"
    Write-ColoredOutput "    Installation Complete!             " "Green"
    Write-ColoredOutput "========================================" "Green"
    Write-ColoredOutput ""
    Write-ColoredOutput "Claude Code has been successfully installed!" "Green"
    Write-ColoredOutput ""
    Write-ColoredOutput "How to use:" "White"
    Write-ColoredOutput "• Right-click on any project folder and select 'Open with Claude Code'" "White"
    Write-ColoredOutput "• Or open PowerShell/Command Prompt and type 'claude-code'" "White"
    Write-ColoredOutput ""
    Write-ColoredOutput "Important:" "Yellow"
    Write-ColoredOutput "The first time you run a command, your browser will open to ask you to log in." "Yellow"
    Write-ColoredOutput "This is normal and only happens once." "Yellow"
    Write-ColoredOutput ""
    Write-ColoredOutput "Press any key to exit..." "White"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-ColoredOutput ""
    Write-ColoredOutput "========================================" "Red"
    Write-ColoredOutput "    Installation Failed                " "Red"
    Write-ColoredOutput "========================================" "Red"
    Write-ColoredOutput ""
    Write-ColoredOutput "Error: $($_.Exception.Message)" "Red"
    Write-ColoredOutput ""
    Write-ColoredOutput "Please check your internet connection and try again." "Yellow"
    Write-ColoredOutput "If the problem persists, please visit:" "Yellow"
    Write-ColoredOutput "https://github.com/anthropics/claude-code/issues" "Cyan"
    Write-ColoredOutput ""
    Write-ColoredOutput "Press any key to exit..." "White"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}