# Configuration File Schema

## Overview

The configuration file uses YAML format and defines all aspects of macOS system configuration.

## File Location

- **Default**: `config.yaml` in the script directory
- **Custom**: Specify with `--config /path/to/config.yaml`

## Schema Structure

```yaml
# System Preferences Configuration
system:
  preferences:
    dock:
      orientation: "left" | "right" | "bottom"
      autohide: true | false
      tilesize: <number>
      magnification: true | false
      # ... additional dock settings
    
    finder:
      show_pathbar: true | false
      show_statusbar: true | false
      preferred_view: "clmv" | "icnv" | "Nlsv" | "Flwv"
      # ... additional finder settings
    
    screenshots:
      location: "<path>"
      format: "png" | "jpg" | "pdf"
      # ... additional screenshot settings
    
    # ... additional system preference sections

# Package Installation
packages:
  formulae:
    - <package_name>
    # ... list of Homebrew formulae
  
  casks:
    - <package_name>
    # ... list of Homebrew casks

# Mac App Store Applications
mas:
  apps:
    - id: <app_store_id>
      name: "<app_name>"
    # ... list of MAS apps

# Direct Downloads
direct_downloads:
  - name: "<application_name>"
    url: "<download_url>"
    install_method: "dmg" | "pkg" | "zip" | "tar"
    # Optional:
    checksum: "<sha256_checksum>"
    version: "<version_string>"

# Dotfile Configuration
dotfiles:
  - target: "<file_path>"  # Supports ~ expansion
    content: |
      <file_content>
    # OR
    source: "<source_file_path>"
    # Optional:
    backup: true | false  # Default: true
    mode: "<octal_permissions>"  # Default: "0644"

# Shell Configuration
shell:
  theme: "<theme_name>"  # e.g., "powerlevel10k"
  plugins:
    - <plugin_name>
    # ... list of zsh plugins
  aliases:
    <alias_name>: "<alias_command>"
    # ... key-value pairs of aliases

# Secrets Management (1Password References)
secrets:
  <secret_name>:
    op_reference: "op://<vault>/<item>/<field>"
  # ... additional secrets
```

## Configuration Sections

### system.preferences

Configures macOS system preferences using `defaults` commands.

**Supported Sections:**
- `dock`: Dock appearance and behavior
- `finder`: Finder preferences
- `screenshots`: Screenshot location and format
- `keyboard`: Keyboard settings
- `trackpad`: Trackpad settings
- `security`: Security and privacy settings
- `general`: General system preferences

### packages

Defines Homebrew packages to install. The script automatically selects the best source (Homebrew → MAS → Direct Download) for each package.

**formulae**: Command-line tools installed via `brew install`
**casks**: GUI applications installed via `brew install --cask`

### mas

Mac App Store applications. Requires `mas` CLI tool and App Store sign-in.

**apps**: List of App Store applications with:
- `id`: App Store ID (numeric)
- `name`: Human-readable name (for logging)

### direct_downloads

Applications to download and install directly from URLs.

**Required fields:**
- `name`: Application name
- `url`: Download URL
- `install_method`: Format type (dmg, pkg, zip, tar)

**Optional fields:**
- `checksum`: SHA256 checksum for verification
- `version`: Version string for tracking

### dotfiles

Configuration files to create or copy.

**Required:**
- `target`: Destination path (supports `~` expansion)

**Content (one of):**
- `content`: Inline file content (YAML multiline string)
- `source`: Path to source file to copy

**Optional:**
- `backup`: Whether to backup existing file (default: `true`)
- `mode`: File permissions in octal (default: `0644`)

### shell

Zsh shell configuration.

**theme**: Zsh theme name (e.g., "powerlevel10k", "oh-my-zsh")
**plugins**: List of zsh plugins to install
**aliases**: Key-value pairs of shell aliases

### secrets

1Password CLI references for secure secret management.

**Format**: `op://<vault>/<item>/<field>`

Example:
```yaml
secrets:
  github_token:
    op_reference: "op://Private/GitHub Token/token"
```

## Validation Rules

### Required Fields
- Configuration file must be valid YAML
- All referenced paths must be valid
- All URLs must be accessible
- All package names must be valid

### Optional Fields
- Most fields have sensible defaults
- Missing optional fields use defaults from architecture

### Type Validation
- Boolean values: `true` | `false`
- String values: Quoted strings
- Numeric values: Integers or floats
- Lists: YAML array syntax
- Objects: YAML object syntax

## Configuration Merging

When multiple configuration files are provided:
1. Load default configuration (if exists)
2. Load user configuration
3. Merge user config over defaults
4. Apply command-line overrides
5. Validate final configuration

## Example Configuration

See `config.yaml.example` (to be created in Phase 4) for a complete example configuration file.

