# User Guide: macOS Configuration Script

## Overview

This script provides a comprehensive, automated way to configure a macOS system for developers and system administrators. It handles system preferences, package installation, shell configuration, and more—all through a simple, maintainable configuration file.

## Target Audience

**Primary Users:** System administrators and developers with advanced technical skills who want to automate macOS setup and configuration.

**Technical Skill Level:** Advanced. Users should be comfortable with:
- Command-line interfaces
- YAML configuration files
- macOS system administration
- Understanding script execution and troubleshooting

## Installation

### Getting the Script

The script is available via GitHub:

```bash
git clone <repository-url>
cd bootstrap
```

### Prerequisites

- macOS (version compatibility will be checked)
- Internet connection
- Administrator access (for system configuration)
- Signed in to Mac App Store (if installing App Store apps)

## First Run Experience

### Initial Setup

1. **Clone or download the repository**
2. **Review the default configuration file** (`config.yaml` or similar)
3. **Customize the configuration** to match your needs (optional)
4. **Run the script:**

```bash
./bootstrap.sh
```

### Configuration File Approach

The script uses a YAML configuration file as the primary interface. On first run:

- The script will look for a configuration file (default: `config.yaml` in the script directory)
- If no configuration file exists, it will be created from a template
- **Prompts are minimal**—only shown when:
  - Required information is missing from the config
  - User confirmation is needed for potentially destructive actions
  - Secrets/credentials need to be entered (if 1Password CLI is not configured)

### Example First Run

```bash
$ ./bootstrap.sh
ℹ️  macOS Configuration Script
====================================================
ℹ️  Loading configuration from config.yaml...
⚠️  Configuration file not found. Creating template...
✅ Template created at config.yaml
ℹ️  Please review and customize config.yaml, then run again.
```

After customizing the config:

```bash
$ ./bootstrap.sh
ℹ️  macOS Configuration Script
====================================================
ℹ️  Loading configuration from config.yaml...
⚠️  Some packages already installed. Overwrite? (y/N): 
```

## Configuration File

### Location

- Default: `config.yaml` in the script directory
- Custom: Specify with `--config /path/to/config.yaml`

### Structure

The configuration file defines:

- **System Preferences**: Dock settings, Finder preferences, hot corners, etc.
- **Application Installation**: Apps and tools with automatic source selection (Homebrew → Mac App Store → Direct Download)
- **Homebrew Packages**: Formulae (command-line tools) and casks (GUI applications)
- **Mac App Store Apps**: Apps to install via `mas`
- **Direct Downloads**: Applications to download and install directly
- **Dotfiles**: Configuration files for various tools (`.gitconfig`, `.vimrc`, `.tmux.conf`, etc.)
- **Shell Configuration**: Zsh plugins, themes, aliases
- **1Password References**: Secrets stored in 1Password (requires 1Password CLI)

### Example Configuration

```yaml
system:
  preferences:
    dock:
      orientation: left
      autohide: true
      tilesize: 36
    finder:
      show_pathbar: true
      preferred_view: clmv
    screenshots:
      location: ~/Documents/Screenshots

# Applications are installed using priority order:
# 1. Homebrew (formulae/casks)
# 2. Mac App Store (if not in Homebrew)
# 3. Direct Download (if not in either)
packages:
  formulae:
    - git
    - wget
    - zsh-autosuggestions
  casks:
    - visual-studio-code
    - cursor
    - 1password

mas:
  apps:
    - id: 1234567890
      name: "Some App Store App"

direct_downloads:
  - name: "Custom App"
    url: "https://example.com/app.dmg"
    install_method: "dmg"  # or "pkg", "zip", "tar"

dotfiles:
  - source: "~/.config/git/config"
    target: "~/.gitconfig"
    content: |
      [user]
        name = Your Name
        email = your.email@example.com
      [core]
        editor = vim
  - source: "~/.config/vim/vimrc"
    target: "~/.vimrc"
    content: |
      set number
      set expandtab
      set tabstop=2

shell:
  theme: powerlevel10k
  plugins:
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  aliases:
    c: clear
    reload: source ~/.zshrc
```

## Running the Script

### Basic Usage

```bash
./bootstrap.sh
```

### Command-Line Options

#### `--config <path>`
Specify a custom configuration file location.

```bash
./bootstrap.sh --config ~/my-config.yaml
```

#### `--overwrite`
Automatically overwrite existing configurations without prompting. Use with caution.

```bash
./bootstrap.sh --overwrite
```

#### `--continue-on-error`
Continue execution even if a step fails, rather than stopping and prompting.

```bash
./bootstrap.sh --continue-on-error
```

#### `--modules <module1,module2>`
Run only specific modules. Available modules:
- `system`: System preferences configuration
- `homebrew`: Homebrew package installation
- `mas`: Mac App Store app installation
- `direct_download`: Direct download installation
- `dotfiles`: Dotfile configuration
- `shell`: Shell configuration

```bash
./bootstrap.sh --modules system,homebrew
```

#### `--help`
Display usage information and available options.

```bash
./bootstrap.sh --help
```

### Combining Options

```bash
./bootstrap.sh --config custom.yaml --modules homebrew,shell --continue-on-error
```

## User Experience During Execution

### Progress Feedback

The script provides **verbose output with progress bars**:

- **Progress bars** show installation progress for packages
- **Color-coded messages**:
  - 🔵 Blue (ℹ️): Informational messages
  - 🟢 Green (✅): Success messages
  - 🟡 Yellow (⚠️): Warnings
  - 🔴 Red (❌): Errors
- **Verbose logging** shows detailed information about each step

### Example Output

```
ℹ️  Configuring System Preferences…
┃██████████████████████████████┃ 100% System Preferences
✅ System Preferences applied

ℹ️  Installing Homebrew packages…
┃████████░░░░░░░░░░░░░░░░░░░░░░┃  40% Installing git...
✅ Installed git
┃████████████████████░░░░░░░░░░┃  60% Installing visual-studio-code...
✅ Installed visual-studio-code
```

### Logging

- **Standard logs** are written to a log file (default: `bootstrap.log` in script directory)
- **WARN level and above** are also displayed on STDOUT
- Logs include timestamps and module information

## Handling Conflicts

### Default Behavior: Ask

By default, when the script encounters existing configurations or installed packages:

1. **Detects the conflict**
2. **Prompts the user** with options:
   - Skip (keep existing)
   - Overwrite (replace with new configuration)
   - Cancel (abort the operation)

### Overwrite Mode

Use `--overwrite` to automatically overwrite without prompting:

```bash
./bootstrap.sh --overwrite
```

**Warning:** This will replace existing configurations. Use with caution.

### Examples of Conflicts

- **System Preferences**: Dock settings already customized
- **Packages**: Homebrew packages already installed
- **Shell Config**: `.zshrc` already exists with customizations
- **1Password CLI**: Already configured with different account

## Error Handling

### Default Behavior: Prompt

When an error occurs:

1. **Error is logged** with details
2. **User is prompted**: Continue or abort?
3. **If continue**: Script proceeds with remaining steps
4. **If abort**: Script exits with error code

### Continue-on-Error Mode

Use `--continue-on-error` to automatically continue past errors:

```bash
./bootstrap.sh --continue-on-error
```

The script will:
- Log all errors
- Display warnings for failed steps
- Continue with remaining operations
- Exit with a summary of successes and failures

### Error Examples

- **Network failure** during package download
- **Permission denied** for system configuration
- **Package not found** in Homebrew
- **1Password CLI** not authenticated

## Idempotency

The script is **idempotent**—safe to run multiple times:

- **Checks before installing**: Verifies if packages are already installed
- **Preserves existing configs**: Only modifies what's specified
- **Tracks state**: Remembers what's been configured to avoid redundant work
- **No side effects**: Running multiple times produces the same result

You can safely:
- Re-run after adding new packages to config
- Re-run to update configurations
- Re-run to verify everything is set up correctly

## macOS Version Compatibility

### Version Checking

The script checks the macOS version and:

- **Warns** if running on an unsupported or untested version
- **Fails gracefully** if critical features aren't available
- **Adapts behavior** when possible (e.g., different defaults commands for different versions)

### Version Requirements

- **Minimum**: macOS 10.15 (Catalina)
- **Recommended**: Latest stable macOS version
- **Tested on**: [To be determined based on testing]

### Handling Version Differences

- **Preferences**: Uses version-appropriate `defaults` commands
- **Package availability**: Checks if packages are available for the macOS version
- **Feature detection**: Detects available features rather than assuming

## Installation Source Priority

The script uses a **priority-based installation system** to automatically select the best source for each application. This ensures you get the most reliable and up-to-date installations.

### Priority Order

Applications are installed using the following priority order:

1. **Homebrew** (Highest Priority)
   - Checks for Homebrew formulae first (command-line tools)
   - Then checks for Homebrew casks (GUI applications)
   - Fastest and most reliable for most applications
   - Automatic updates via `brew upgrade`

2. **Mac App Store** (Second Priority)
   - If not available in Homebrew, attempts installation via `mas` CLI
   - Requires Mac App Store sign-in
   - Good for apps that are only available in the App Store

3. **Direct Download** (Fallback)
   - If not available in Homebrew or Mac App Store, downloads directly
   - Supports DMG, PKG, ZIP, and TAR formats
   - Manual installation process
   - Useful for custom or proprietary applications

### How It Works

When you specify an application in the configuration:

```yaml
apps:
  - name: "Some Application"
```

The script will:
1. Check if available as Homebrew cask → install via Homebrew
2. If not, check if available in Mac App Store → install via `mas`
3. If not, check `direct_downloads` section → download and install directly
4. Log which method was used for transparency

### Explicit Source Override

You can explicitly specify the source if needed:

```yaml
apps:
  - name: "Some App"
    source: "homebrew"  # Force Homebrew installation
  - name: "Another App"
    source: "mas"       # Force Mac App Store installation
  - name: "Custom App"
    source: "direct"    # Force direct download
```

### Benefits

- **Automatic optimization**: Always uses the best available source
- **Flexibility**: Works even if one source is unavailable
- **Transparency**: Logs show which source was used
- **Maintainability**: Update priorities in one place

## Dotfile Configuration

The script can create and manage **dotfiles** (configuration files that start with a dot, like `.gitconfig`, `.vimrc`, `.tmux.conf`).

### What Are Dotfiles?

Dotfiles are configuration files for various command-line tools and applications. They're typically stored in your home directory and customize the behavior of tools like:
- Git (`.gitconfig`)
- Vim/Neovim (`.vimrc`, `.config/nvim/init.vim`)
- Tmux (`.tmux.conf`)
- Bash/Zsh (`.bashrc`, `.zshrc`)
- And many more

### Configuration Format

Dotfiles are defined in the `dotfiles` section of your configuration:

```yaml
dotfiles:
  - target: "~/.gitconfig"
    content: |
      [user]
        name = Your Name
        email = your.email@example.com
      [core]
        editor = vim
        autocrlf = input
      [alias]
        st = status
        co = checkout
        br = branch
  
  - target: "~/.vimrc"
    content: |
      set number
      set expandtab
      set tabstop=2
      set shiftwidth=2
      syntax on
  
  - target: "~/.tmux.conf"
    content: |
      set -g default-terminal "screen-256color"
      set -g mouse on
      bind-key -n C-h select-pane -L
      bind-key -n C-l select-pane -R
```

### Dotfile Options

Each dotfile entry supports:

- **`target`** (required): Path where the file should be created (supports `~` expansion)
- **`content`** (required): The file content (YAML multiline string)
- **`source`** (optional): Path to source file to copy instead of inline content
- **`backup`** (optional): Whether to backup existing file (default: `true`)
- **`mode`** (optional): File permissions (default: `0644`)

### Example with Options

```yaml
dotfiles:
  - target: "~/.gitconfig"
    source: "~/.config/git/config"  # Copy from source file
    backup: true
    mode: "0644"
  
  - target: "~/.vimrc"
    content: |
      " My vim configuration
      set number
    backup: true
  
  - target: "~/.ssh/config"
    content: |
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_rsa
    mode: "0600"  # More restrictive permissions for SSH config
```

### Handling Existing Dotfiles

By default, the script will:

1. **Backup existing files**: Creates a timestamped backup (e.g., `.gitconfig.backup.20250127_103000`)
2. **Prompt before overwriting**: Asks for confirmation (unless `--overwrite` is used)
3. **Merge option**: For some file types, can merge rather than replace (future feature)

### Dotfile Management Best Practices

1. **Version control your dotfiles**: Keep your dotfile configurations in version control
2. **Use source files**: Reference source files when possible for easier editing
3. **Test configurations**: Verify dotfiles work after creation
4. **Backup first**: Always backup existing dotfiles before modification
5. **Document customizations**: Add comments explaining non-standard configurations

### Supported Dotfile Types

The script can create dotfiles for any tool. Common examples:

- **Git**: `.gitconfig`, `.gitignore_global`
- **Shell**: `.bashrc`, `.zshrc`, `.profile`
- **Editors**: `.vimrc`, `.config/nvim/init.vim`, `.emacs`
- **Terminal**: `.tmux.conf`, `.screenrc`
- **SSH**: `.ssh/config`, `.ssh/known_hosts`
- **Custom**: Any dotfile you need

## Secrets Management

### 1Password CLI Integration

The script integrates with **1Password CLI** for secure secret management:

1. **Early Installation**: 1Password CLI is installed early in the process
2. **Configuration**: Script helps configure 1Password CLI if needed
3. **Secret References**: Configuration file can reference secrets stored in 1Password
4. **On-the-Fly Retrieval**: Secrets are retrieved as needed during execution

### Configuration Example

```yaml
secrets:
  github_token:
    op_reference: "op://Private/GitHub Token/token"
  api_key:
    op_reference: "op://Work/API Keys/production"
```

### Fallback Behavior

If 1Password CLI is not available or a secret is not found:

- **User is prompted** to enter the secret manually
- **Secret is used** for the current operation only (not stored)
- **Process continues** after secret is provided

### Security Best Practices

- Secrets are never stored in configuration files
- Secrets are retrieved only when needed
- 1Password CLI authentication is required before use
- Manual entry is available as fallback

## Post-Installation

### Automated Steps

The script handles several post-installation tasks automatically:

- **Shell reload**: Sources new shell configuration
- **Dock restart**: Applies Dock changes immediately
- **Finder restart**: Applies Finder changes immediately
- **Verification**: Checks that installations succeeded

### Manual Steps

Some steps may require manual action:

- **System restart**: May be recommended for some system preference changes
- **App Store sign-in**: Required before installing App Store apps
- **1Password authentication**: May require manual sign-in on first use

### Verification

After completion, the script provides:

- **Summary report**: What was installed/configured
- **Verification status**: Success/failure for each module
- **Next steps**: Any manual actions required

## Troubleshooting

### Common Issues

**Issue**: Script fails with permission errors
- **Solution**: Run with appropriate permissions or use `sudo` where needed

**Issue**: Packages fail to install
- **Solution**: Check internet connection, verify Homebrew is working, check package names

**Issue**: System preferences don't apply
- **Solution**: May require restart or manual application

**Issue**: 1Password CLI not working
- **Solution**: Ensure 1Password CLI is installed and authenticated

### Getting Help

- Check the log file for detailed error messages
- Review the configuration file for syntax errors
- Verify macOS version compatibility
- Check that all prerequisites are met

## Best Practices

1. **Review configuration before running**: Understand what will be changed
2. **Backup important files**: Especially `.zshrc` and other dotfiles
3. **Test on non-critical system first**: Verify behavior before production use
4. **Version control your config**: Keep your `config.yaml` in version control
5. **Run incrementally**: Use `--modules` to test individual components
6. **Check logs**: Review log files if something goes wrong

## Uninstallation

**Note**: The script does not provide an uninstall/rollback capability. To revert changes:

- **System Preferences**: Manually reset via System Preferences app
- **Packages**: Uninstall via Homebrew: `brew uninstall <package>`
- **Shell Config**: Restore from backup (script creates backups automatically)
- **App Store Apps**: Uninstall via App Store or manually

Consider keeping backups of original configurations before running the script.
