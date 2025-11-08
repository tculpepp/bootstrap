# macOS Configuration Script

A comprehensive, modular script system for automating macOS system configuration and application installation. Configure your Mac with a simple YAML configuration file.

## Features

- 🎯 **System Preferences**: Automate Dock, Finder, and screenshot settings
- 📦 **Package Management**: Install applications via Homebrew, Mac App Store, or direct download
- 🔄 **Priority-Based Installation**: Automatically selects the best source (Homebrew → MAS → Direct Download)
- 📝 **Dotfile Management**: Create and manage configuration files for your tools
- 🐚 **Shell Configuration**: Set up zsh themes, plugins, and aliases
- 🔐 **Secrets Management**: Integrate with 1Password CLI for secure credential handling
- ✅ **Idempotent**: Safe to run multiple times
- 📊 **Progress Reporting**: Visual progress bars and detailed logging

## Quick Start

### Option 1: Quick Install Script (Recommended)

**Method 1: Download and run (interactive):**
```bash
# Download the install script
curl -O https://raw.githubusercontent.com/username/bootstrap/main/install.sh

# Run it (will prompt for repository URL)
bash install.sh
```

**Method 2: With repository URL:**
```bash
# Download and run with repository URL
curl -fsSL https://raw.githubusercontent.com/username/bootstrap/main/install.sh | bash -s -- https://github.com/username/bootstrap.git
```

**Method 3: Copy script content directly:**
1. Open `install.sh` in your browser
2. Copy the entire script content
3. Paste into a local file: `nano install.sh` (paste, then save with Ctrl+O, Enter, Ctrl+X)
4. Run: `bash install.sh`

The install script will:
- Check if git is installed (install via Homebrew if needed)
- Prompt you for the repository URL (or use the one provided)
- Clone the repository

Then run the bootstrap script:
```bash
cd bootstrap
./bootstrap.sh
```

On first run, the script will automatically create `config.yaml` from the example template.

### Option 2: Manual Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd bootstrap
   ```

2. **Run the script:**
   ```bash
   ./bootstrap.sh
   ```
   
   On first run, the script will automatically create `config.yaml` from the example template.

3. **Customize your configuration:**
   ```bash
   # Edit config.yaml with your preferences
   nano config.yaml
   ```

4. **Run again to apply:**
   ```bash
   ./bootstrap.sh
   ```

## Prerequisites

- **macOS 10.15 (Catalina) or later**
- **Internet connection** (for downloading packages)
- **Administrator access** (for system configuration)
- **Mac App Store sign-in** (if installing App Store apps)
- **1Password CLI** (optional, for secrets management)

## Installation

### Basic Installation

```bash
# Clone the repository
git clone <repository-url>
cd bootstrap

# Make script executable
chmod +x bootstrap.sh

# Run the script
./bootstrap.sh
```

### Recommended: Install yq for Full YAML Support

For full configuration support (especially arrays), install `yq`:

```bash
# Install via Homebrew (recommended)
brew install yq

# Or the script will install it if configured in config.yaml
```

## Configuration

The script uses a YAML configuration file (`config.yaml`) to define all settings. See `config.yaml.example` for a complete example.

### Configuration Sections

- **`system.preferences`**: Dock, Finder, and screenshot settings
- **`packages`**: Homebrew formulae and casks
- **`mas`**: Mac App Store applications
- **`direct_downloads`**: Applications to download directly
- **`dotfiles`**: Configuration files to create
- **`git`**: Git user name and email
- **`shell`**: Zsh theme, plugins, and aliases
- **`secrets`**: 1Password CLI references

### Example Configuration

```yaml
system:
  preferences:
    dock:
      orientation: "left"
      autohide: true
      tilesize: 36

packages:
  formulae:
    - git
    - vim
  casks:
    - visual-studio-code
    - cursor

shell:
  theme: "powerlevel10k"
  plugins:
    - zsh-autosuggestions
  aliases:
    ll: "ls -lah"
    gs: "git status"
```

See `config.yaml.example` for a complete example with all options.

## Usage

### Basic Usage

```bash
./bootstrap.sh
```

### Command-Line Options

```bash
# Use custom configuration file
./bootstrap.sh --config ~/my-config.yaml

# Automatically overwrite existing configurations
./bootstrap.sh --overwrite

# Continue on errors
./bootstrap.sh --continue-on-error

# Run only specific modules
./bootstrap.sh --modules system,homebrew

# Show help
./bootstrap.sh --help
```

### Module Selection

Run only specific modules:

```bash
./bootstrap.sh --modules system,homebrew,git,shell
```

Available modules:
- `system` - System preferences
- `homebrew` - Homebrew packages
- `mas` - Mac App Store apps
- `direct-download` - Direct downloads
- `dotfiles` - Dotfile configuration
- `git` - Git user configuration
- `shell` - Shell configuration

## How It Works

### Installation Priority

The script uses a priority-based installation system:

1. **Homebrew** (Highest Priority)
   - Checks for formulae first (command-line tools)
   - Then checks for casks (GUI applications)

2. **Mac App Store** (Second Priority)
   - If not available in Homebrew, attempts installation via `mas` CLI

3. **Direct Download** (Fallback)
   - Downloads and installs from URLs (DMG, PKG, ZIP, TAR)

### Idempotency

The script is **idempotent**—safe to run multiple times:

- Checks if packages are already installed before installing
- Backs up existing dotfiles before modifying
- Only applies system preferences that have changed
- Tracks state to avoid redundant work

## Project Structure

```
bootstrap/
├── bootstrap.sh              # Main entry point
├── config.yaml.example       # Example configuration
├── lib/                      # Core modules
│   ├── logging.sh           # Logging system
│   ├── config.sh            # Configuration parser
│   ├── system.sh            # System preferences
│   ├── homebrew.sh          # Homebrew management
│   ├── mas.sh               # Mac App Store
│   ├── direct-download.sh   # Direct downloads
│   ├── dotfiles.sh          # Dotfile management
│   ├── shell.sh             # Shell configuration
│   ├── secrets.sh           # 1Password integration
│   └── installer.sh         # Installation orchestration
├── docs/                     # Documentation
├── logs/                     # Log files
└── state/                    # State tracking
```

## Documentation

- **[User Guide](.conductor/user_guide.md)** - Comprehensive user documentation
- **[Configuration Schema](docs/CONFIG_SCHEMA.md)** - Complete configuration reference
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Architecture](.conductor/architecture.md)** - Technical architecture details

## Logging

All operations are logged to `logs/bootstrap.log`. Logs include:
- Timestamps
- Module names
- Operation details
- Success/failure status

View logs:
```bash
tail -f logs/bootstrap.log
```

## Error Handling

The script handles errors gracefully:

- **Non-fatal errors**: Logged as warnings, execution continues
- **Fatal errors**: Stop execution and prompt user (or continue with `--continue-on-error`)
- **Detailed error messages**: Include context and suggested fixes

## Security

- **Secrets**: Never stored in configuration files
- **1Password Integration**: Secure secret retrieval via 1Password CLI
- **Checksum Verification**: Optional SHA256 checksums for downloads
- **Backup Creation**: Automatic backups before modifying files

## Requirements

- macOS 10.15 (Catalina) or later
- Bash 3.2+ (stock macOS `/bin/bash`)
- Internet connection
- Administrator privileges (for system configuration)

## Contributing

This project follows the [Conductor Methodology](conductor.md) for project management. See `.conductor/` directory for project structure and guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Version

Current version: **1.0.0**

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Support

For issues, questions, or contributions:
- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- Review the [User Guide](.conductor/user_guide.md)
- Check logs in `logs/bootstrap.log`
- See [Configuration Examples](docs/EXAMPLES.md) for use case examples

## Acknowledgments

Built with a focus on clarity, maintainability, and user experience. Follows best practices for bash scripting and system administration.

