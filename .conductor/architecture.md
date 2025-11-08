# Architecture Document: macOS Configuration Script

## Overview

This document defines the technical architecture for the macOS configuration script. The system is designed as a modular, maintainable solution that prioritizes clarity, extensibility, and reliability.

## Core Design Principles

1. **Modularity**: Functionality is separated into discrete, testable modules
2. **Configuration-Driven**: Behavior is controlled via YAML configuration files
3. **Idempotency**: Script can be run multiple times safely
4. **Error Resilience**: Graceful error handling with user control
5. **Portability**: Compatible with stock macOS bash (3.2+)
6. **Maintainability**: Clear structure, comprehensive logging, well-documented code

## System Architecture

### High-Level Structure

```
bootstrap/
├── bootstrap.sh              # Main entry point
├── config.yaml               # Default configuration
├── lib/                      # Core modules
│   ├── logging.sh           # Logging utilities
│   ├── config.sh            # Configuration parser
│   ├── system.sh            # System preferences
│   ├── homebrew.sh          # Homebrew package management
│   ├── mas.sh               # Mac App Store integration
│   ├── direct_download.sh   # Direct download installation
│   ├── installer.sh         # Installation source priority logic
│   ├── dotfiles.sh          # Dotfile management
│   ├── shell.sh             # Shell configuration
│   └── secrets.sh           # 1Password CLI integration
├── state/                    # State tracking
│   └── state.json           # Installation/configuration state
└── logs/                     # Log files
    └── bootstrap.log        # Execution logs
```

## Module System

### Module Communication

Modules communicate through:

1. **Shared Functions**: Common utilities (logging, config parsing) are sourced
2. **Return Codes**: Functions return 0 for success, non-zero for failure
3. **Environment Variables**: Shared state via environment variables
4. **State File**: Persistent state stored in JSON format
5. **Configuration Object**: Parsed YAML configuration passed between modules

### Module Loading Pattern

```bash
# At the top of each module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/config.sh"
```

### Dependency Management

Dependencies are managed through **explicit source statements**:

- Each module explicitly sources its dependencies
- Dependencies are loaded in order (logging → config → feature modules)
- Circular dependencies are avoided through careful design
- Each module can function independently for testing

### Module Interface Standard

All modules follow a standard interface:

```bash
# Module: example.sh
# Usage: module_function [args]
# Returns: 0 on success, 1 on failure
module_function() {
  local arg1="$1"
  
  # Validate inputs
  [[ -z "$arg1" ]] && { log_error "arg1 required"; return 1; }
  
  # Main logic
  # ...
  
  # Update state
  update_state "module" "function" "completed"
  
  return 0
}
```

## Configuration System

### Configuration Format: YAML

YAML is chosen for:
- Human-readable and writable
- Supports complex nested structures
- Widely understood format
- Good tooling support

### Configuration Schema

```yaml
# Top-level structure
system:
  preferences: { ... }
  
packages:
  formulae: [ ... ]
  casks: [ ... ]
  
mas:
  apps: [ ... ]
  
direct_downloads:
  - name: string
    url: string
    install_method: "dmg" | "pkg" | "zip" | "tar"
  
dotfiles:
  - target: string
    content: string | null
    source: string | null
    backup: boolean
    mode: string
  
shell:
  theme: string
  plugins: [ ... ]
  aliases: { ... }
  
secrets:
  secret_name:
    op_reference: "op://vault/item/field"
```

### Configuration Parsing

- **Parser**: Custom bash-based YAML parser (or `yq` if available)
- **Validation**: Schema validation on load
- **Defaults**: Sensible defaults for optional values
- **Error Handling**: Clear error messages for invalid configurations

### Configuration Loading Flow

1. **Load default config** (if exists)
2. **Load user config** (merge with defaults)
3. **Validate schema**
4. **Resolve secrets** (1Password references)
5. **Store in memory** as associative array or similar structure

## Logging System

### Log Levels

- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **WARN**: Warning messages (also to STDOUT)
- **ERROR**: Error messages (also to STDOUT)
- **FATAL**: Critical errors that stop execution

### Logging Strategy

**File Logging:**
- All log levels written to `logs/bootstrap.log`
- Log rotation (keep last N logs)
- Timestamps and module names included

**STDOUT Logging:**
- WARN and above displayed to user
- Progress bars and status updates
- Color-coded for visibility

### Logging Implementation

```bash
# Logging functions
log_debug() { echo "[DEBUG] $*" >> "$LOG_FILE"; }
log_info() { echo "[INFO] $*" >> "$LOG_FILE"; log_to_stdout "ℹ️  $*"; }
log_warn() { echo "[WARN] $*" >> "$LOG_FILE"; log_to_stdout "⚠️  $*"; }
log_error() { echo "[ERROR] $*" >> "$LOG_FILE"; log_to_stdout "❌ $*"; }
```

## State Management

### State Tracking

System state is tracked in `state/state.json`:

```json
{
  "version": "1.0.0",
  "last_run": "2025-01-27T10:30:00Z",
  "system": {
    "preferences_applied": true,
    "applied_at": "2025-01-27T10:30:15Z"
  },
  "packages": {
    "installed": ["git", "wget"],
    "installed_at": "2025-01-27T10:31:00Z"
  },
  "shell": {
    "configured": true,
    "backup_location": "~/.zshrc.backup.20250127"
  }
}
```

### State Operations

- **Read State**: Load JSON state file on startup
- **Update State**: Write state after each major operation
- **Check State**: Query state to determine if action is needed
- **Reset State**: Option to clear state for fresh run

### State Benefits

- **Idempotency**: Know what's already done
- **Resume**: Can resume after interruption
- **Verification**: Track what was configured
- **Debugging**: Understand what happened in previous runs

## Module Details

### 1. Logging Module (`lib/logging.sh`)

**Responsibilities:**
- Log message formatting
- File and STDOUT output
- Progress bar rendering
- Color management

**Key Functions:**
- `log_info()`, `log_warn()`, `log_error()`, `log_success()`
- `show_progress_bar()`
- `init_logging()`

### 2. Configuration Module (`lib/config.sh`)

**Responsibilities:**
- YAML parsing
- Configuration validation
- Default value merging
- Configuration access helpers

**Key Functions:**
- `load_config()`
- `get_config_value()`
- `validate_config()`

### 3. System Module (`lib/system.sh`)

**Responsibilities:**
- macOS system preferences configuration
- `defaults` command execution
- Preference validation
- System service restarts

**Key Functions:**
- `configure_system_preferences()`
- `apply_dock_settings()`
- `apply_finder_settings()`
- `restart_system_services()`

### 4. Homebrew Module (`lib/homebrew.sh`)

**Responsibilities:**
- Homebrew installation/update
- Package installation (formulae and casks)
- Package verification
- Dependency checking

**Key Functions:**
- `install_homebrew()`
- `install_package()`
- `is_package_installed()`
- `update_homebrew()`

### 5. Shell Module (`lib/shell.sh`)

**Responsibilities:**
- Shell configuration file generation
- Plugin installation
- Theme configuration
- Backup management

**Key Functions:**
- `configure_shell()`
- `backup_existing_config()`
- `install_shell_plugins()`
- `generate_zshrc()`

### 6. Mac App Store Module (`lib/mas.sh`)

**Responsibilities:**
- MAS CLI installation
- App installation
- App verification
- Account status checking

**Key Functions:**
- `install_mas()`
- `install_mas_app()`
- `check_mas_account()`

### 7. Direct Download Module (`lib/direct_download.sh`)

**Responsibilities:**
- Download applications from URLs
- Handle DMG, PKG, ZIP, TAR formats
- Extract and install applications
- Verify downloads

**Key Functions:**
- `download_application()`
- `install_dmg()`
- `install_pkg()`
- `extract_archive()`
- `verify_download()`

### 8. Installer Module (`lib/installer.sh`)

**Responsibilities:**
- Coordinate installation source priority
- Determine best source for each application
- Route to appropriate installation module
- Track installation method used

**Key Functions:**
- `install_application()`
- `determine_installation_source()`
- `try_homebrew_install()`
- `try_mas_install()`
- `try_direct_download()`

**Installation Priority Logic:**
1. Check Homebrew (formulae, then casks)
2. If not found, check Mac App Store
3. If not found, use direct download (if configured)
4. Log which method was used

### 9. Dotfiles Module (`lib/dotfiles.sh`)

**Responsibilities:**
- Create dotfile configurations
- Backup existing dotfiles
- Handle file permissions
- Support inline content and source file copying

**Key Functions:**
- `create_dotfile()`
- `backup_dotfile()`
- `copy_dotfile_from_source()`
- `set_dotfile_permissions()`
- `expand_home_path()`

### 10. Secrets Module (`lib/secrets.sh`)

**Responsibilities:**
- 1Password CLI integration
- Secret retrieval
- Secret caching (in memory only)
- Fallback to user prompts

**Key Functions:**
- `setup_1password_cli()`
- `get_secret()`
- `resolve_secret_reference()`
- `prompt_for_secret()`

## Parallel Execution

### Strategy

Where possible and **low risk of conflict**, operations run in parallel:

**Safe for Parallel:**
- Installing independent Homebrew packages (formulae)
- Installing independent Homebrew casks
- Reading configuration values

**Not Safe for Parallel:**
- System preference changes (sequential to avoid conflicts)
- Shell configuration (must be atomic)
- State file updates (require locking)

### Implementation

```bash
# Example: Parallel package installation
install_packages_parallel() {
  local packages=("$@")
  local pids=()
  
  for package in "${packages[@]}"; do
    install_package "$package" &
    pids+=($!)
  done
  
  # Wait for all and check results
  for pid in "${pids[@]}"; do
    wait "$pid" || log_warn "Package installation failed"
  done
}
```

## Error Handling Strategy

### Error Levels

1. **Non-Fatal**: Log warning, continue execution
2. **Fatal (Prompt)**: Stop, ask user to continue or abort (default)
3. **Fatal (Auto)**: Stop immediately (with `--continue-on-error`)

### Error Handling Pattern

```bash
function_name() {
  if ! some_operation; then
    log_error "Operation failed: reason"
    if [[ "$CONTINUE_ON_ERROR" == "true" ]]; then
      return 1  # Continue but mark as failed
    else
      prompt_user "Continue despite error?" || exit 1
    fi
  fi
}
```

### Error Recovery

- **State tracking** allows resuming from last successful operation
- **Backup files** allow rollback of configuration changes
- **Detailed logging** aids in troubleshooting

## Testing Strategy

### Testing Framework

Create a testing/mocking framework for development:

**Components:**
- **Mock functions**: Replace system calls (defaults, brew, etc.)
- **Test harness**: Run modules in isolation
- **Assertion helpers**: Verify expected behavior
- **Fixture system**: Provide test configurations

### Test Structure

```bash
# test/system_test.sh
source "$SCRIPT_DIR/lib/system.sh"

test_configure_dock() {
  mock_defaults_write
  configure_dock_settings
  assert_defaults_called_with "com.apple.dock" "orientation" "left"
}
```

### Testing Approach

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test module interactions
3. **Mock System Calls**: Don't actually modify system
4. **CI Integration**: Run tests automatically

## Secrets Management Architecture

### 1Password CLI Integration

**Early Installation:**
- 1Password CLI is installed as a priority dependency
- Configured before other modules that need secrets

**Secret Resolution Flow:**

1. **Check 1Password CLI**: Is it installed and authenticated?
2. **Parse Reference**: Extract vault/item/field from config
3. **Retrieve Secret**: Use `op read` command
4. **Cache in Memory**: Store in associative array (never to disk)
5. **Fallback**: If unavailable, prompt user

### Secret Reference Format

```yaml
secrets:
  github_token:
    op_reference: "op://Private/GitHub Token/token"
```

Parsed as:
- Vault: `Private`
- Item: `GitHub Token`
- Field: `token`

### Security Considerations

- **No disk storage**: Secrets only in memory
- **No logging**: Secrets never appear in logs
- **Immediate use**: Retrieved just before use, discarded after
- **Authentication required**: 1Password CLI must be authenticated
- **Fallback available**: Manual entry if 1Password unavailable

## macOS Version Compatibility

### Version Detection

```bash
get_macos_version() {
  sw_vers -productVersion
}

check_macos_compatibility() {
  local version=$(get_macos_version)
  local major=$(echo "$version" | cut -d. -f1)
  local minor=$(echo "$version" | cut -d. -f2)
  
  if [[ $major -lt 10 ]] || [[ $major -eq 10 && $minor -lt 15 ]]; then
    log_warn "macOS version $version may not be fully supported"
    prompt_user "Continue anyway?" || exit 1
  fi
}
```

### Version-Specific Behavior

- **Feature Detection**: Check for feature availability rather than version
- **Graceful Degradation**: Skip unsupported features with warning
- **Version Warnings**: Inform user of potential issues

## Command-Line Interface

### Argument Parsing

```bash
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      --overwrite)
        OVERWRITE_MODE=true
        shift
        ;;
      --continue-on-error)
        CONTINUE_ON_ERROR=true
        shift
        ;;
      --modules)
        MODULES="$2"
        shift 2
        ;;
      --help)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}
```

### Option Processing Order

1. Parse command-line arguments
2. Load configuration file
3. Apply command-line overrides to config
4. Validate final configuration
5. Execute selected modules

## Installation Source Priority System

### Priority-Based Installation

The system implements a **priority-based installation mechanism** that automatically selects the best source for each application. This ensures reliable, maintainable installations.

### Priority Order

1. **Homebrew** (Priority 1 - Highest)
   - First checks formulae (command-line tools)
   - Then checks casks (GUI applications)
   - Fastest and most reliable
   - Automatic dependency management

2. **Mac App Store** (Priority 2)
   - Attempts installation via `mas` CLI
   - Requires App Store authentication
   - Fallback if not in Homebrew

3. **Direct Download** (Priority 3 - Fallback)
   - Downloads from URL
   - Supports DMG, PKG, ZIP, TAR formats
   - Manual installation process
   - Used when other sources unavailable

### Implementation Flow

```bash
install_application() {
  local app_name="$1"
  
  # Try Homebrew first
  if try_homebrew_install "$app_name"; then
    log_info "Installed $app_name via Homebrew"
    return 0
  fi
  
  # Try Mac App Store second
  if try_mas_install "$app_name"; then
    log_info "Installed $app_name via Mac App Store"
    return 0
  fi
  
  # Try direct download last
  if try_direct_download "$app_name"; then
    log_info "Installed $app_name via direct download"
    return 0
  fi
  
  log_error "Could not install $app_name from any source"
  return 1
}
```

### Source Detection

- **Homebrew**: Check via `brew search` and `brew info`
- **Mac App Store**: Check via `mas search`
- **Direct Download**: Check configuration for `direct_downloads` entry

### Benefits

- **Automatic optimization**: Always uses best available source
- **Resilience**: Works even if one source fails
- **Transparency**: Logs which source was used
- **Maintainability**: Single point of configuration

## Dotfile Management Architecture

### Overview

The dotfile management system allows users to define configuration files for various tools and applications. It supports both inline content and source file copying.

### Dotfile Structure

Each dotfile entry contains:
- **target**: Destination path (supports `~` expansion)
- **content**: Inline file content (YAML multiline string)
- **source**: Optional source file path (alternative to content)
- **backup**: Whether to backup existing file (default: true)
- **mode**: File permissions (default: 0644)

### Processing Flow

```
1. Parse dotfile configuration
2. Expand home directory paths (~ → $HOME)
3. Check if target file exists
4. If exists and backup=true:
   - Create timestamped backup
   - Prompt user (unless --overwrite)
5. Create dotfile:
   - If source specified: Copy from source
   - If content specified: Write content
6. Set file permissions
7. Update state file
```

### Backup Strategy

- **Timestamped backups**: `.filename.backup.YYYYMMDD_HHMMSS`
- **Backup location**: Same directory as target file
- **Backup preservation**: Never overwrite existing backups
- **Backup cleanup**: Optional cleanup of old backups (future feature)

### Path Expansion

- **Home directory**: `~` expands to `$HOME`
- **Relative paths**: Resolved relative to home directory
- **Absolute paths**: Used as-is
- **Nested directories**: Created automatically if needed

### File Permissions

- **Default**: 0644 (readable by all, writable by owner)
- **SSH configs**: 0600 (readable/writable by owner only)
- **Executable scripts**: 0755 (if needed)
- **Configurable**: Per-dotfile via `mode` field

### Error Handling

- **Missing source file**: Log error, skip dotfile
- **Permission denied**: Log error, prompt user
- **Invalid content**: Validate before writing
- **Backup failure**: Warn but continue (if overwrite allowed)

## Main Execution Flow

```
1. Initialize
   ├── Parse arguments
   ├── Initialize logging
   ├── Load configuration
   └── Check macOS version

2. Setup Dependencies
   ├── Install/verify 1Password CLI (if secrets needed)
   ├── Install/verify Homebrew
   └── Install/verify MAS CLI (if MAS apps needed)

3. Execute Modules (based on --modules or config)
   ├── System preferences
   ├── Application installation (priority-based)
   │   ├── Homebrew packages
   │   ├── Mac App Store apps
   │   └── Direct downloads
   ├── Dotfile configuration
   └── Shell configuration

4. Finalize
   ├── Update state file
   ├── Generate summary report
   └── Display completion message
```

## Performance Considerations

### Optimization Strategies

- **Parallel execution** where safe
- **Skip already-installed** packages (idempotency check)
- **Batch operations** where possible (e.g., multiple defaults writes)
- **State caching** to avoid redundant checks

### Bottlenecks

- **Network operations**: Package downloads
- **System calls**: defaults writes, service restarts
- **1Password CLI**: Secret retrieval (network + auth)

## Future Extensibility

### Plugin System (Not Implemented)

While not in initial scope, architecture supports future plugin system:

- **Plugin directory**: `plugins/` for custom modules
- **Plugin interface**: Standard function signatures
- **Plugin discovery**: Auto-load plugins
- **Plugin config**: Plugin-specific configuration sections

### Configuration Extensions

- **Custom modules**: Add new module types via config
- **Conditional execution**: Run modules based on conditions
- **Environment-specific configs**: Dev, staging, production configs

## Security Considerations

1. **No secrets in config files**: Only references
2. **Minimal permissions**: Request only what's needed
3. **Input validation**: Validate all user inputs and config values
4. **Safe defaults**: Conservative behavior by default
5. **Audit trail**: Comprehensive logging of all actions
