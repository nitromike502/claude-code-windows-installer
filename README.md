# Claude Code Windows Installer

A one-click installer for [Claude Code](https://claude.ai/code) on Windows systems. This installer automatically handles all dependencies and provides a seamless installation experience for Windows users.

## What It Does

This installer automatically sets up everything you need to run Claude Code on Windows:

- **Installs Claude Code** via npm (`@anthropic-ai/claude-code`)
- **Manages dependencies** - Downloads and installs Git and Node.js if needed
- **Sets up version management** - Installs nvm-windows for better Node.js handling
- **Adds Windows integration** - Creates right-click context menu for folders
- **Handles permissions** - Automatically requests admin privileges when needed
- **Provides testing options** - Force reinstall flags for development and troubleshooting

After installation, you can right-click any folder and select "Open with Claude Code" or run `claude-code` from any command prompt.

## Quick Install

**Automated Installation:**
1. Download the installer files to your Windows machine
2. Double-click `✅ START HERE - Install Claude Code.bat`
3. Click "Yes" when prompted for admin privileges
4. Wait for installation to complete

**Manual Installation (recommended for review):**
1. Download the installer files
2. Review the PowerShell script at `src/installer.ps1`
3. Run the installer: `✅ START HERE - Install Claude Code.bat`

## Features

- ✅ **One-click installation** - Simply double-click the batch file to start
- ✅ **Automatic dependency management** - Installs Git and Node.js if missing
- ✅ **Smart version detection** - Uses nvm-windows for better Node.js version management
- ✅ **Architecture aware** - Automatically detects 32-bit vs 64-bit Windows
- ✅ **Windows Explorer integration** - Adds right-click context menu for folders
- ✅ **Admin privilege handling** - Automatically requests elevation when needed
- ✅ **Force reinstall options** - Can force reinstall dependencies for testing
- ✅ **Configuration-driven** - Easy to update versions without code changes

## Usage

After installation completes:

1. **Verify installation**: Open a new command prompt and run:
   ```cmd
   claude-code --version
   ```

2. **Start using Claude Code**: 
   - **Via context menu**: Right-click any project folder → "Open with Claude Code"
   - **Via command line**: Navigate to your project and run `claude-code`

3. **First-time setup**: The first time you run Claude Code, your browser will open asking you to log in. This is normal and only happens once.

## Command Line Options

The installer supports several command-line options for different installation scenarios:

### Basic Installation
```batch
# Standard installation - detects existing dependencies
"✅ START HERE - Install Claude Code.bat"
```

### Force Reinstall Options
```batch
# Force reinstall everything (useful for testing or troubleshooting)
"✅ START HERE - Install Claude Code.bat" -Force

# Force reinstall Git only (if Git is corrupted)
"✅ START HERE - Install Claude Code.bat" -ForceGit

# Force reinstall Node.js/nvm only (for Node.js issues)
"✅ START HERE - Install Claude Code.bat" -ForceNode
```

### PowerShell Direct Usage
```powershell
# Navigate to src folder and run directly
cd src
.\installer.ps1                    # Normal installation
.\installer.ps1 -Force             # Force reinstall all dependencies
.\installer.ps1 -ForceGit          # Force reinstall Git only
.\installer.ps1 -ForceNode         # Force reinstall Node.js/nvm only
```

## Installation Process

The installer performs these steps automatically:

1. **Checks system requirements**
   - Verifies if Git is installed
   - Checks Node.js version (requires v20.11.0+)
   
2. **Installs missing dependencies**
   - Downloads and installs Git if missing
   - Installs nvm-windows for Node.js version management
   - Installs Node.js v20.18.0 via nvm
   
3. **Installs Claude Code**
   - Runs `npm install -g @anthropic-ai/claude-code`
   
4. **Sets up Windows integration**
   - Adds "Open with Claude Code" to folder context menus

## Architecture

This installer follows a modular, configuration-driven architecture:

### Core Components

- **Batch Launcher**: User-friendly entry point with parameter support
- **PowerShell Installer**: Main logic with admin privilege management
- **JSON Configuration**: Centralized version and URL management
- **Force Flag System**: Selective reinstallation for testing and troubleshooting

### Design Philosophy

- **Transparency**: All source code is readable and reviewable
- **Maintainability**: Versions controlled via JSON configuration, not hardcoded
- **Developer-friendly**: Uses nvm-windows for Node.js version management
- **Windows-native**: Leverages PowerShell and batch files for optimal Windows integration

### Version Strategy

This installer currently supports:
- **Node.js**: v20.18.0 (via nvm-windows for flexibility)
- **Git**: v2.47.1 (architecture-aware downloads)
- **Claude Code**: Latest from npm (@anthropic-ai/claude-code)

### Configuration

The installer behavior is controlled by `src/config.json`:

```json
{
  "dependencies": {
    "nodejs": {
      "version": "20.18.0",          // Version to install
      "minimumVersion": "20.11.0"    // Minimum required version
    },
    "git": {
      "version": "2.47.1",           // Git version to install
      "minimumVersion": "2.0.0"      // Minimum required version
    }
  },
  "installer": {
    "contextMenuText": "Open with Claude Code",  // Right-click menu text
    "contextMenuIcon": "shell32.dll,3"          // Menu icon
  }
}
```

To update versions, simply edit the JSON file - no code changes required.

## Requirements

- **Windows 7 or later** (32-bit or 64-bit)
- **Internet connection** for downloading dependencies
- **Administrator privileges** (requested automatically)

## Troubleshooting

### Installation Fails
- Check internet connection
- Ensure you clicked "Yes" for admin privileges
- Try running with `-Force` flag to reinstall dependencies

### Context Menu Not Appearing
- Installation requires admin privileges to modify registry
- Try reinstalling with admin privileges

### Node.js Version Issues
- The installer uses nvm-windows for better version management
- You can later use `nvm list` and `nvm use <version>` to switch versions
- Old MSI installations may conflict - uninstall them first

## File Structure

```
claude-code-windows-installer/
├── ✅ START HERE - Install Claude Code.bat  # Main launcher
├── src/
│   ├── installer.ps1                        # PowerShell installer script
│   └── config.json                          # Configuration file
├── README.md                                # This file
├── LICENSE                                  # MIT License
└── CLAUDE.md                               # Development documentation
```

## Development

This installer is designed for ease of maintenance:

- **Versions** are configured in `config.json`, not hardcoded
- **URLs** use templates with `{version}` and `{arch}` placeholders
- **Architecture detection** works for both 32-bit and 64-bit systems
- **Error handling** provides clear user-friendly messages

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
