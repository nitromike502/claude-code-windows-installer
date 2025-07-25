# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Windows installer for Claude Code that provides a one-click installation experience. The project consists of PowerShell scripts, batch files, and JSON configuration to automatically install Claude Code and its dependencies on Windows systems.

## Architecture

### Core Components

1. **Batch Launcher** (`START HERE - Install Claude Code.bat`)
   - Entry point for users
   - Simple launcher without parameter complexity
   - Provides Windows-native experience

2. **PowerShell Installer** (`src/installer.ps1`)
   - Main installation logic
   - Admin privilege management
   - Dependency detection and installation
   - Error handling and user feedback

3. **Configuration File** (`src/config.json`)
   - Version management for dependencies
   - URL templates for downloads
   - UI customization settings

### Key Design Decisions

#### nvm-windows Over MSI
- **Chosen**: nvm-windows for Node.js installation
- **Rationale**: Provides version management capabilities, avoids conflicts with future nvm usage
- **Trade-off**: Slightly more complex installation but much better developer experience

#### Configuration-Driven Architecture
- **Pattern**: JSON configuration file controls all versions and URLs
- **Benefits**: Easy updates without code changes, maintainable by non-developers
- **Implementation**: Template URLs with `{version}` and `{arch}` placeholders

#### Architecture Detection
- **Method**: `[Environment]::Is64BitOperatingSystem` for system detection
- **Coverage**: Handles both 32-bit and 64-bit Windows installations
- **Fallback**: Different installation paths and download URLs per architecture

## Development Patterns

### Error Handling Strategy
```powershell
try {
    # Installation logic
    Write-ColoredOutput "Success message" "Green"
} catch {
    throw "Failed to install X: $($_.Exception.Message)"
}
```

### Configuration Access Pattern
```powershell
$script:Config = Get-InstallerConfig
$version = $script:Config.dependencies.nodejs.version
```

### Interactive Prompt Implementation
- **Pattern**: User-friendly confirmation prompts for all decisions
- **Usage**: `Get-UserConfirmation` function with default choices
- **Logic**: Conditional flows based on user responses

## Common Issues and Solutions

### Admin Privilege Management
- **Issue**: PowerShell scripts need elevation for system changes
- **Solution**: Auto-detection with `Test-Administrator` and self-elevation
- **Pattern**: Restart script with `Start-Process -Verb RunAs`

### PATH Management
- **Issue**: Newly installed tools not available in current session
- **Solution**: Manual PATH updates for current PowerShell session
- **Example**: `$env:Path += ";$nodePath"`

### nvm-windows Integration
- **Issue**: nvm-windows uses batch scripts, not PowerShell cmdlets
- **Solution**: Shell out to cmd.exe for nvm commands
- **Pattern**: `Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "nvm", "install", $version`

## Testing Approach

### Interactive Testing
- Run installer with existing dependencies to test prompts
- Test "reinstall anyway" choices for each component
- Verify context menu Keep/Update/Remove functionality

### Configuration Testing
- Modify `config.json` to test different versions
- Invalid JSON testing for error handling
- URL template testing with different architectures

## File Structure Rationale

```
├── START HERE - Install Claude Code.bat  # User-friendly entry point
├── src/                                     # Source code isolation  
│   ├── installer.ps1                        # Main logic
│   └── config.json                          # Configuration data
├── README.md                                # User documentation
├── LICENSE                                  # Legal requirements
└── CLAUDE.md                               # Development documentation
```

## Security Considerations

### Admin Privilege Usage
- **Scope**: Only requested when needed for system modifications
- **Justification**: Required for program installation and registry modifications
- **Mitigation**: Clear user prompts explaining why elevation is needed

### Download Security
- **Sources**: Only official GitHub releases and nodejs.org
- **Verification**: HTTPS-only downloads
- **Execution**: Downloaded files executed with known safe parameters

## Maintenance Guidelines

### Version Updates
1. Edit `src/config.json` version numbers
2. Test by running installer and choosing to reinstall components
3. No code changes required for routine updates

### URL Updates
- Update template URLs in config.json if GitHub/Node.js change release patterns
- Test with both 32-bit and 64-bit placeholder values

### Adding New Dependencies
1. Add to `dependencies` section in config.json
2. Create `Install-X` function following existing patterns
3. Add detection logic in main installation flow
4. Update README.md with new dependency information

## Build and Test Commands

Since this is a PowerShell/batch project, there are no traditional build commands. Testing is done by:

```powershell
# Test interactive installation
.\installer.ps1

# Test with existing dependencies (to trigger prompts)
# Run installer multiple times and choose different options:
# - Keep existing vs reinstall dependencies
# - Add/Update/Remove context menu options
# - Test different user response patterns
```