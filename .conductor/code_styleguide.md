# Code Style Guide

## Core Principle

**Clarity Over Cleverness**: Write code that is immediately understandable to any developer, even if they're not familiar with bash scripting. Prioritize readability, maintainability, and explicit behavior over clever one-liners or obscure optimizations.

## Base Standards

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) as the foundation
- Use `bash` 3.2+ compatibility (stock macOS `/bin/bash`)
- Prefer portability over bash-specific features when possible

## Naming Conventions

### Functions
- Use `snake_case` for function names
- Use descriptive, verb-based names: `install_homebrew_packages()`, `configure_system_preferences()`
- Prefix helper/utility functions with `_` if they're internal: `_log_message()`, `_validate_config()`

### Variables
- Use `UPPER_SNAKE_CASE` for constants and global variables: `SCRIPT_DIR`, `CONFIG_FILE`
- Use `lower_snake_case` for local variables: `package_name`, `install_status`
- Use descriptive names: `installed_packages` not `pkgs`

### Files
- Use `kebab-case` for script files: `install-packages.sh`, `configure-system.sh`
- Use descriptive names that indicate purpose

## Code Structure

### Function Organization
```bash
# Function documentation comment
# Usage: function_name [args]
# Returns: description of return value or exit code
function_name() {
  local var1="$1"  # Always quote variables
  local var2="$2"
  
  # Validate inputs
  [[ -z "$var1" ]] && { log_error "var1 required"; return 1; }
  
  # Main logic
  # ...
  
  return 0
}
```

### Error Handling
- Use `set -Eeuo pipefail` at the top of scripts
- Always check return codes: `command || { log_error "message"; return 1; }`
- Use `|| true` only when failure is expected and acceptable
- Provide meaningful error messages

### Comments
- Use `#` for single-line comments
- Use `#` blocks for section headers: `###############################################################################`
- Explain **why**, not **what** (code should be self-documenting)
- Document complex logic or non-obvious behavior

### Indentation
- Use 2 spaces for indentation (not tabs)
- Align continuation lines appropriately
- Keep line length under 100 characters when possible

## Best Practices

### Quoting
- Always quote variables: `"$var"` not `$var`
- Quote command substitutions: `"$(command)"`
- Quote strings in comparisons: `[[ "$var" == "value" ]]`

### Arrays
- Declare arrays explicitly: `declare -a packages=()`
- Use proper array syntax: `packages+=("item")`
- Iterate safely: `for item in "${array[@]}"; do`

### Functions
- Use `local` for function-scoped variables
- Return meaningful exit codes (0 = success, non-zero = failure)
- Keep functions focused on a single responsibility

### Testing
- Test functions in isolation when possible
- Use `[[ ]]` for conditionals (more robust than `[ ]`)
- Validate inputs at function boundaries

## Example Structure

```bash
#!/usr/bin/env bash
###############################################################################
#  Module: install-packages.sh
#  Purpose: Install Homebrew packages
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/config.sh"

###############################################################################
#  Install a single package
#  Usage: install_package <package_name> <package_type>
#  Returns: 0 on success, 1 on failure
###############################################################################
install_package() {
  local package_name="$1"
  local package_type="$2"
  
  [[ -z "$package_name" ]] && { log_error "Package name required"; return 1; }
  [[ -z "$package_type" ]] && { log_error "Package type required"; return 1; }
  
  log_info "Installing $package_name ($package_type)..."
  
  if [[ "$package_type" == "cask" ]]; then
    brew install --cask "$package_name" || { log_error "Failed to install $package_name"; return 1; }
  else
    brew install "$package_name" || { log_error "Failed to install $package_name"; return 1; }
  fi
  
  log_success "Installed $package_name"
  return 0
}
```

