# Module Design Specification

## Overview

This document defines the detailed design specifications for all modules in the macOS configuration script system.

## Module Dependency Graph

```
bootstrap.sh (main)
├── lib/logging.sh (no dependencies)
├── lib/config.sh (depends on: logging.sh)
├── lib/secrets.sh (depends on: logging.sh, config.sh)
├── lib/system.sh (depends on: logging.sh, config.sh)
├── lib/homebrew.sh (depends on: logging.sh, config.sh)
├── lib/mas.sh (depends on: logging.sh, config.sh, homebrew.sh)
├── lib/direct-download.sh (depends on: logging.sh, config.sh)
├── lib/installer.sh (depends on: logging.sh, config.sh, homebrew.sh, mas.sh, direct-download.sh)
├── lib/dotfiles.sh (depends on: logging.sh, config.sh)
└── lib/shell.sh (depends on: logging.sh, config.sh, homebrew.sh)
```

## Module Interface Standards

### Function Signature Pattern

All public module functions follow this pattern:

```bash
# Function: module_action
# Usage: module_action <required_arg> [optional_arg]
# Returns: 0 on success, 1 on failure
# Side Effects: [description of any side effects]
module_action() {
  local required_arg="$1"
  local optional_arg="${2:-default_value}"
  
  # Input validation
  [[ -z "$required_arg" ]] && { log_error "required_arg is required"; return 1; }
  
  # Main implementation
  # ...
  
  return 0
}
```

### Error Handling Pattern

All modules use consistent error handling:

```bash
module_function() {
  if ! some_operation; then
    log_error "Operation failed: reason"
    if [[ "${CONTINUE_ON_ERROR:-false}" == "true" ]]; then
      return 1  # Continue but mark as failed
    else
      prompt_user "Continue despite error?" || return 1
    fi
  fi
}
```

### State Management Pattern

Modules that need to track state should use the state management functions:

```bash
# Update state after successful operation
update_state() {
  local module="$1"
  local operation="$2"
  local status="$3"
  # Implementation in state management module
}

# Check state before operation
check_state() {
  local module="$1"
  local operation="$2"
  # Returns 0 if already done, 1 if needs to be done
}
```

## Module Naming Conventions

### File Names
- Use `kebab-case.sh`: `system-preferences.sh`, `direct-download.sh`
- Be descriptive: `homebrew.sh` not `brew.sh`
- Match module purpose: `dotfiles.sh` not `config-files.sh`

### Function Names
- Use `snake_case`: `install_package()`, `configure_dock()`
- Start with verb: `install_`, `configure_`, `check_`, `validate_`
- Be specific: `install_homebrew_package()` not `install()`

### Internal/Private Functions
- Prefix with `_`: `_validate_input()`, `_log_debug()`
- Not part of public API
- Can be changed without affecting other modules

## Module Documentation Requirements

Each module must include:

1. **Header comment block** with:
   - Module name
   - Purpose description
   - Dependencies list

2. **Function documentation** for each public function:
   - Purpose
   - Usage/parameters
   - Return values
   - Side effects

3. **Usage examples** in comments for complex functions

## Module Responsibilities

### logging.sh
- Log message formatting and output
- Progress bar rendering
- Color management
- Log file management

### config.sh
- YAML parsing
- Configuration validation
- Default value merging
- Configuration access helpers

### system.sh
- macOS system preferences
- `defaults` command execution
- System service restarts
- Preference validation

### homebrew.sh
- Homebrew installation/update
- Package installation (formulae and casks)
- Package verification
- Dependency checking

### mas.sh
- MAS CLI installation
- App installation
- App verification
- Account status checking

### direct-download.sh
- Download from URLs
- Handle DMG, PKG, ZIP, TAR formats
- Extract and install
- Verify downloads

### installer.sh
- Coordinate installation source priority
- Determine best source for each application
- Route to appropriate installation module
- Track installation method used

### dotfiles.sh
- Create dotfile configurations
- Backup existing dotfiles
- Handle file permissions
- Support inline content and source file copying

### shell.sh
- Shell configuration file generation
- Plugin installation
- Theme configuration
- Backup management

### secrets.sh
- 1Password CLI integration
- Secret retrieval
- Secret caching (in memory only)
- Fallback to user prompts

## Module Testing Requirements

Each module should be:
- **Testable in isolation**: Can be sourced and tested independently
- **Mockable**: System calls can be mocked for testing
- **Idempotent**: Safe to run multiple times
- **Error-resilient**: Handles errors gracefully

