#!/usr/bin/env bash
###############################################################################
#  Module: config.sh
#  Purpose: Configuration file parsing and validation
#  Dependencies: logging.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

###############################################################################
#  Global Variables
###############################################################################

CONFIG_FILE=""
CONFIG_LOADED=false
YQ_AVAILABLE=false

###############################################################################
#  Check if yq is Available
#  Usage: _check_yq_available
#  Returns: 0 if available, 1 if not
###############################################################################

_check_yq_available() {
  if command -v yq &> /dev/null; then
    YQ_AVAILABLE=true
    return 0
  else
    YQ_AVAILABLE=false
    return 1
  fi
}

###############################################################################
#  Get Config Value Using yq
#  Usage: _get_config_value_yq <yaml_path>
#  Returns: Config value or empty string
###############################################################################

_get_config_value_yq() {
  local yaml_path="$1"
  
  if [[ "$YQ_AVAILABLE" == "true" ]] && [[ -f "$CONFIG_FILE" ]]; then
    yq eval "$yaml_path" "$CONFIG_FILE" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

###############################################################################
#  Simple YAML Parser (Basic Support)
#  Usage: _get_config_value_simple <key_path>
#  Returns: Config value or empty string
#  Note: This is a basic parser for simple cases only
###############################################################################

_get_config_value_simple() {
  local key_path="$1"
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo ""
    return 1
  fi
  
  # Convert key path (e.g., "system.preferences.dock.orientation") to grep pattern
  # This is a very basic implementation for simple key-value pairs
  # For complex YAML, yq should be used
  
  local key
  key=$(echo "$key_path" | sed 's/\./\\./g')
  
  # Try to extract value (very basic - only works for simple cases)
  grep -E "^[[:space:]]*${key}:" "$CONFIG_FILE" 2>/dev/null | \
    sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*["'\'']?([^"'\'']*)["'\'']?[[:space:]]*$/\1/' || echo ""
}

###############################################################################
#  Get Config Value
#  Usage: get_config_value <yaml_path> [default_value]
#  Returns: Config value or default if not found
###############################################################################

get_config_value() {
  local yaml_path="$1"
  local default_value="${2:-}"
  
  # Allow access during validation if CONFIG_FILE is set (even if CONFIG_LOADED is not yet true)
  if [[ "$CONFIG_LOADED" != "true" ]] && [[ -z "$CONFIG_FILE" ]]; then
    log_warn "[config] Configuration not loaded. Call load_config() first."
    echo "$default_value"
    return 1
  fi
  
  local value=""
  
  # Try yq first if available
  if [[ "$YQ_AVAILABLE" == "true" ]]; then
    value=$(_get_config_value_yq "$yaml_path")
  else
    # Fall back to simple parser
    value=$(_get_config_value_simple "$yaml_path")
  fi
  
  # Return value or default
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

###############################################################################
#  Check if Config Section Exists
#  Usage: has_config_section <section_path>
#  Returns: 0 if exists, 1 if not
###############################################################################

has_config_section() {
  local section_path="$1"
  local value
  value=$(get_config_value "$section_path")
  
  if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Validate Configuration File
#  Usage: validate_config [config_file]
#  Returns: 0 if valid, 1 if invalid
###############################################################################

validate_config() {
  local config_file="${1:-$CONFIG_FILE}"
  
  if [[ -z "$config_file" ]]; then
    log_error "[config] No configuration file specified"
    return 1
  fi
  
  if [[ ! -f "$config_file" ]]; then
    log_error "[config] Configuration file not found: $config_file"
    return 1
  fi
  
  # Check if file is readable
  if [[ ! -r "$config_file" ]]; then
    log_error "[config] Configuration file is not readable: $config_file"
    return 1
  fi
  
  # Basic YAML syntax check (if yq available)
  if [[ "$YQ_AVAILABLE" == "true" ]]; then
    if ! yq eval '.' "$config_file" &> /dev/null; then
      log_error "[config] Invalid YAML syntax in: $config_file"
      return 1
    fi
  else
    # Basic validation without yq - check file is not empty and has some structure
    if [[ ! -s "$config_file" ]]; then
      log_error "[config] Configuration file is empty: $config_file"
      return 1
    fi
    # Check for basic YAML structure (has at least one colon)
    if ! grep -q ':' "$config_file"; then
      log_warn "[config] Configuration file may not be valid YAML (no colons found)"
    fi
  fi
  
  log_debug "[config] Configuration file validated: $config_file"
  return 0
}

###############################################################################
#  Load Configuration File
#  Usage: load_config [config_file] [default_config_file]
#  Returns: 0 on success, 1 on failure
###############################################################################

load_config() {
  local config_file="${1:-}"
  local default_config="${2:-}"
  
  # Determine config file location
  if [[ -z "$config_file" ]]; then
    # Get script directory
    local script_dir
    if [[ -f "${BASH_SOURCE[0]}" ]]; then
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      if [[ "$(basename "$script_dir")" == "lib" ]]; then
        script_dir="$(dirname "$script_dir")"
      fi
    else
      script_dir="$(pwd)"
    fi
    
    config_file="$script_dir/config.yaml"
  fi
  
  # Check for yq availability
  _check_yq_available || log_warn "[config] yq not available, using basic YAML parser"
  
  # Set CONFIG_FILE temporarily for validation (but don't set CONFIG_LOADED yet)
  CONFIG_FILE="$config_file"
  
  # Validate configuration file (enhanced if available)
  if ! validate_config_enhanced "$config_file"; then
    # If default config provided and main config doesn't exist, try default
    if [[ -n "$default_config" ]] && [[ -f "$default_config" ]]; then
      log_info "[config] Using default configuration: $default_config"
      config_file="$default_config"
      CONFIG_FILE="$config_file"
      if ! validate_config_enhanced "$config_file"; then
        CONFIG_FILE=""
        return 1
      fi
    else
      CONFIG_FILE=""
      return 1
    fi
  fi
  
  # Only set CONFIG_LOADED=true after successful validation
  CONFIG_LOADED=true
  
  log_info "[config] Configuration loaded from: $config_file"
  
  return 0
}

###############################################################################
#  Get Config File Path
#  Usage: get_config_file_path
#  Returns: Path to config file or empty string
###############################################################################

get_config_file_path() {
  echo "$CONFIG_FILE"
}

###############################################################################
#  Check if Config is Loaded
#  Usage: is_config_loaded
#  Returns: 0 if loaded, 1 if not
###############################################################################

is_config_loaded() {
  if [[ "$CONFIG_LOADED" == "true" ]] && [[ -n "$CONFIG_FILE" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Get Array from Config
#  Usage: get_config_array <yaml_path>
#  Returns: Space-separated list of values (for use in arrays)
###############################################################################

get_config_array() {
  local yaml_path="$1"
  
  if [[ "$YQ_AVAILABLE" == "true" ]] && [[ -f "$CONFIG_FILE" ]]; then
    # Use yq to get array values
    yq eval "$yaml_path[]" "$CONFIG_FILE" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || echo ""
  else
    # Basic array parsing (very limited)
    log_warn "[config] Array parsing without yq is limited. Install yq for full support."
    echo ""
  fi
}

###############################################################################
#  Expand Home Directory in Path
#  Usage: expand_home_path <path>
#  Returns: Expanded path
###############################################################################

expand_home_path() {
  local path="$1"
  
  # Expand ~ to $HOME
  if [[ "$path" == ~* ]]; then
    echo "${path/#\~/$HOME}"
  else
    echo "$path"
  fi
}

###############################################################################
#  Validate Configuration Schema
#  Usage: validate_config_schema [config_file]
#  Returns: 0 if valid, 1 if invalid
###############################################################################

validate_config_schema() {
  local config_file="${1:-$CONFIG_FILE}"
  
  if [[ -z "$config_file" ]] || [[ ! -f "$config_file" ]]; then
    return 1
  fi
  
  local errors=0
  
  # Validate dock orientation if present
  if has_config_section "system.preferences.dock.orientation"; then
    local orientation
    orientation=$(get_config_value "system.preferences.dock.orientation")
    if [[ "$orientation" != "left" ]] && [[ "$orientation" != "right" ]] && [[ "$orientation" != "bottom" ]]; then
      log_warn "[config] Invalid dock orientation: $orientation (should be left, right, or bottom)"
      errors=$((errors + 1))
    fi
  fi
  
  # Validate screenshot format if present
  if has_config_section "system.preferences.screenshots.format"; then
    local format
    format=$(get_config_value "system.preferences.screenshots.format")
    if [[ "$format" != "png" ]] && [[ "$format" != "jpg" ]] && [[ "$format" != "pdf" ]]; then
      log_warn "[config] Invalid screenshot format: $format (should be png, jpg, or pdf)"
      errors=$((errors + 1))
    fi
  fi
  
  # Validate install_method in direct_downloads (if yq available)
  if [[ "$YQ_AVAILABLE" == "true" ]] && has_config_section "direct_downloads"; then
    local install_methods
    install_methods=$(yq eval '.direct_downloads[].install_method' "$config_file" 2>/dev/null)
    while IFS= read -r method; do
      if [[ -n "$method" ]] && [[ "$method" != "dmg" ]] && [[ "$method" != "pkg" ]] && [[ "$method" != "zip" ]] && [[ "$method" != "tar" ]]; then
        log_warn "[config] Invalid install_method: $method (should be dmg, pkg, zip, or tar)"
        errors=$((errors + 1))
      fi
    done <<< "$install_methods"
  fi
  
  if [[ $errors -gt 0 ]]; then
    log_warn "[config] Found $errors validation warning(s)"
    return 1
  fi
  
  return 0
}

###############################################################################
#  Initialize Configuration File
#  Usage: init_config_file [config_file] [example_file]
#  Returns: 0 on success, 1 on failure
###############################################################################

init_config_file() {
  local config_file="${1:-config.yaml}"
  local example_file="${2:-config.yaml.example}"
  
  # Get script directory
  local script_dir
  if [[ -f "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$(basename "$script_dir")" == "lib" ]]; then
      script_dir="$(dirname "$script_dir")"
    fi
  else
    script_dir="$(pwd)"
  fi
  
  # Resolve paths
  if [[ "$config_file" != /* ]]; then
    config_file="$script_dir/$config_file"
  fi
  if [[ "$example_file" != /* ]]; then
    example_file="$script_dir/$example_file"
  fi
  
  # Check if config file already exists
  if [[ -f "$config_file" ]]; then
    log_warn "[config] Configuration file already exists: $config_file"
    return 1
  fi
  
  # Check if example file exists
  if [[ ! -f "$example_file" ]]; then
    log_error "[config] Example configuration file not found: $example_file"
    return 1
  fi
  
  # Copy example to config
  if cp "$example_file" "$config_file"; then
    log_success "[config] Created configuration file: $config_file"
    log_info "[config] Please edit $config_file to customize your settings"
    return 0
  else
    log_error "[config] Failed to create configuration file: $config_file"
    return 1
  fi
}

###############################################################################
#  Enhanced Configuration Validation
#  Usage: validate_config_enhanced [config_file]
#  Returns: 0 if valid, 1 if invalid
###############################################################################

validate_config_enhanced() {
  local config_file="${1:-$CONFIG_FILE}"
  
  # Basic validation
  if ! validate_config "$config_file"; then
    return 1
  fi
  
  # Schema validation
  validate_config_schema "$config_file" || log_warn "[config] Schema validation found issues (continuing anyway)"
  
  # Additional checks
  if [[ "$YQ_AVAILABLE" == "true" ]]; then
    # Check for required fields in direct_downloads
    if has_config_section "direct_downloads"; then
      local count
      count=$(yq eval '.direct_downloads | length' "$config_file" 2>/dev/null || echo "0")
      local i
      for ((i=0; i<count; i++)); do
        local name
        name=$(yq eval ".direct_downloads[$i].name" "$config_file" 2>/dev/null)
        local url
        url=$(yq eval ".direct_downloads[$i].url" "$config_file" 2>/dev/null)
        local method
        method=$(yq eval ".direct_downloads[$i].install_method" "$config_file" 2>/dev/null)
        
        if [[ -z "$name" ]] || [[ -z "$url" ]] || [[ -z "$method" ]]; then
          log_warn "[config] direct_downloads[$i] missing required fields (name, url, or install_method)"
        fi
      done
    fi
  fi
  
  log_debug "[config] Enhanced validation completed"
  return 0
}

