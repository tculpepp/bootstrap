# Dependency Management Design

## Overview

The dependency management system ensures modules are loaded in the correct order and dependencies are resolved properly.

## Module Loading Order

Modules must be loaded in dependency order:

1. **Core Utilities** (no dependencies)
   - `logging.sh` - Logging functions
   
2. **Configuration** (depends on: logging.sh)
   - `config.sh` - Configuration parsing
   
3. **Secrets** (depends on: logging.sh, config.sh)
   - `secrets.sh` - 1Password CLI integration
   
4. **System Modules** (depends on: logging.sh, config.sh)
   - `system.sh` - System preferences
   - `homebrew.sh` - Homebrew management
   - `direct-download.sh` - Direct downloads
   - `dotfiles.sh` - Dotfile management
   
5. **App Store** (depends on: logging.sh, config.sh, homebrew.sh)
   - `mas.sh` - Mac App Store integration
   
6. **Installer** (depends on: logging.sh, config.sh, homebrew.sh, mas.sh, direct-download.sh)
   - `installer.sh` - Priority-based installation
   
7. **Shell** (depends on: logging.sh, config.sh, homebrew.sh)
   - `shell.sh` - Shell configuration

## Module Sourcing Pattern

### Standard Pattern

Each module follows this sourcing pattern:

```bash
#!/usr/bin/env bash
###############################################################################
#  Module: module-name.sh
#  Purpose: Brief description
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies in order
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"
# ... additional dependencies
```

### Path Resolution

All modules use `SCRIPT_DIR` for reliable path resolution:

```bash
# Correct: Use SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Incorrect: Relative paths (breaks when script is sourced from different location)
source "./logging.sh"
```

## Dependency Validation

### Check Dependencies Before Sourcing

```bash
check_dependency() {
  local dep="$1"
  local dep_path="$SCRIPT_DIR/$dep"
  
  if [[ ! -f "$dep_path" ]]; then
    log_error "Dependency not found: $dep_path"
    return 1
  fi
  
  return 0
}

# Validate before sourcing
check_dependency "logging.sh" || exit 1
source "$SCRIPT_DIR/logging.sh"
```

### Verify Required Functions

After sourcing, verify required functions exist:

```bash
verify_dependency() {
  local function_name="$1"
  
  if ! declare -f "$function_name" &> /dev/null; then
    log_error "Required function not found: $function_name"
    return 1
  fi
  
  return 0
}

# After sourcing config.sh
verify_dependency "load_config" || exit 1
verify_dependency "get_config_value" || exit 1
```

## Circular Dependency Prevention

### Design Rules

1. **No circular dependencies**: Module A cannot depend on Module B if Module B depends on Module A
2. **Dependency graph must be acyclic**: Use dependency graph to verify
3. **Shared utilities in core modules**: Common functionality goes in `logging.sh` or `config.sh`

### Dependency Graph Validation

```bash
# Validate no circular dependencies
validate_dependency_graph() {
  # Implementation: Check for cycles in dependency graph
  # Returns 0 if valid, 1 if cycles detected
}
```

## Module Interface Contracts

### Function Availability

Each module documents which functions it provides and which it requires:

```bash
# Module: homebrew.sh
# Provides:
#   - install_homebrew()
#   - install_package()
#   - is_package_installed()
# Requires:
#   - log_info(), log_error(), log_success() from logging.sh
#   - get_config_value() from config.sh
```

### Version Compatibility

Modules should check for compatible versions of dependencies:

```bash
check_logging_version() {
  # Verify logging.sh provides required functions
  local required_functions=("log_info" "log_error" "log_success")
  
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" &> /dev/null; then
      log_error "Incompatible logging.sh version: missing $func"
      return 1
    fi
  done
}
```

## Main Script Loading

### Bootstrap Loading Pattern

The main `bootstrap.sh` script loads modules in dependency order:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load core utilities first
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/config.sh"

# Load feature modules
source "$SCRIPT_DIR/lib/secrets.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/homebrew.sh"
source "$SCRIPT_DIR/lib/direct-download.sh"
source "$SCRIPT_DIR/lib/dotfiles.sh"
source "$SCRIPT_DIR/lib/mas.sh"
source "$SCRIPT_DIR/lib/installer.sh"
source "$SCRIPT_DIR/lib/shell.sh"
```

### Conditional Loading

Some modules may be loaded conditionally:

```bash
# Only load mas.sh if MAS apps are configured
if has_mas_apps; then
  source "$SCRIPT_DIR/lib/mas.sh"
fi
```

## Dependency Documentation

### Module Header

Each module documents its dependencies in the header:

```bash
###############################################################################
#  Module: module-name.sh
#  Purpose: Brief description
#  Dependencies: logging.sh, config.sh, homebrew.sh
###############################################################################
```

### README Documentation

The `lib/README.md` documents the dependency graph and loading order.

## Testing Dependencies

### Isolation Testing

Test modules in isolation by mocking dependencies:

```bash
# test/homebrew_test.sh
# Mock logging functions
log_info() { echo "INFO: $*"; }
log_error() { echo "ERROR: $*"; }

# Source module under test
source "$SCRIPT_DIR/lib/homebrew.sh"

# Run tests
test_install_package() {
  # Test implementation
}
```

### Dependency Verification

Test that dependencies are properly loaded:

```bash
test_dependencies_loaded() {
  source "$SCRIPT_DIR/lib/homebrew.sh"
  
  # Verify required functions exist
  assert_function_exists "log_info"
  assert_function_exists "get_config_value"
}
```

## Best Practices

1. **Explicit Dependencies**: Always list dependencies in module header
2. **Path Resolution**: Use `SCRIPT_DIR` for all relative paths
3. **Validate Before Use**: Check dependencies exist before sourcing
4. **Verify Functions**: Verify required functions exist after sourcing
5. **Document Contracts**: Document what functions a module provides/requires
6. **Avoid Circular Dependencies**: Design dependency graph carefully
7. **Minimal Dependencies**: Only depend on what you need
8. **Test Isolation**: Test modules independently with mocked dependencies

