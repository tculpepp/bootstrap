# Library Modules

This directory contains the core modules for the macOS configuration script system.

## Module Structure

Each module is a self-contained bash script that follows a standard interface pattern.

## Module Naming Conventions

- **File names**: Use `kebab-case.sh` (e.g., `logging.sh`, `system-preferences.sh`)
- **Function names**: Use `snake_case` with descriptive verbs (e.g., `install_package()`, `configure_dock()`)
- **Internal functions**: Prefix with `_` (e.g., `_log_message()`, `_validate_input()`)

## Module Interface Standard

All modules must follow this interface pattern:

```bash
#!/usr/bin/env bash
###############################################################################
#  Module: module-name.sh
#  Purpose: Brief description of module purpose
#  Dependencies: list-dependencies-here
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"

###############################################################################
#  Public Function: function_name
#  Usage: function_name [args]
#  Returns: 0 on success, 1 on failure
###############################################################################
function_name() {
  local arg1="$1"
  
  # Validate inputs
  [[ -z "$arg1" ]] && { log_error "arg1 required"; return 1; }
  
  # Main logic
  # ...
  
  # Update state if needed
  # update_state "module" "function" "completed"
  
  return 0
}
```

## Module Dependencies

Modules should explicitly source their dependencies at the top of the file. Dependencies are loaded in this order:

1. **Core utilities**: `logging.sh`, `config.sh` (if needed)
2. **Feature modules**: Other specific modules as needed

## Module List

### Core Modules (Phase 3 Implementation)

- `logging.sh` - Logging and progress reporting
- `config.sh` - Configuration parsing and validation
- `system.sh` - System preferences configuration
- `homebrew.sh` - Homebrew package management
- `mas.sh` - Mac App Store integration
- `direct-download.sh` - Direct download installation
- `installer.sh` - Priority-based installation coordination
- `dotfiles.sh` - Dotfile management
- `shell.sh` - Shell configuration
- `secrets.sh` - 1Password CLI integration

## Module Communication

Modules communicate through:
- **Shared functions**: Common utilities sourced from other modules
- **Return codes**: 0 for success, non-zero for failure
- **Environment variables**: Shared state (minimal use)
- **State file**: Persistent state in `../state/state.json`
- **Configuration object**: Parsed YAML configuration

## Testing

Each module should be testable in isolation. See `architecture.md` for testing strategy.

