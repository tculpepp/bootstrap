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
  
  # Convert key path (e.g., "system.preferences.dock.orientation") to array
  # Split by dots to get nested keys
  local keys
  IFS='.' read -ra keys <<< "$key_path"
  
  # Find the section by following the nested structure
  local num_keys=${#keys[@]}
  local target_key="${keys[$((num_keys - 1))]}"  # Last key is the one we want the value for
  # Build parent keys array (all keys except the last) - bash 3.2 compatible
  local parent_keys=()
  local i
  for ((i=0; i<$((num_keys - 1)); i++)); do
    parent_keys+=("${keys[$i]}")
  done
  
  # First, find the parent section by following the key path
  local line_num=0
  local indent_stack=()
  local key_stack=()
  
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    
    # Skip empty lines and comments
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    
    # Get indentation level (count leading spaces)
    local indent=0
    while [[ ${line:$indent:1} == " " ]]; do
      indent=$((indent + 1))
    done
    
    # Extract key from line (everything before the colon)
    local line_key
    line_key=$(echo "$line" | sed 's/[[:space:]]*\([^:]*\):.*/\1/' | xargs)
    
    # Remove keys from stack that are at same or greater indentation (bash 3.2 compatible)
    local stack_size=${#indent_stack[@]:-0}
    while [[ $stack_size -gt 0 ]]; do
      local last_indent="${indent_stack[$((stack_size - 1))]}"
      if [[ $last_indent -ge $indent ]]; then
        # Remove last element by creating new array without it
        local new_indent_stack=()
        local new_key_stack=()
        local j
        for ((j=0; j<$((stack_size - 1)); j++)); do
          new_indent_stack+=("${indent_stack[$j]}")
          new_key_stack+=("${key_stack[$j]}")
        done
        if [[ ${#new_indent_stack[@]} -gt 0 ]]; then
          indent_stack=("${new_indent_stack[@]}")
          key_stack=("${new_key_stack[@]}")
        else
          indent_stack=()
          key_stack=()
        fi
        stack_size=${#indent_stack[@]:-0}
      else
        break
      fi
    done
    
    # Add current key to stack
    indent_stack+=("$indent")
    key_stack+=("$line_key")
    
    # Build current path from stack
    local current_path
    current_path=$(IFS='.'; echo "${key_stack[*]}")
    
    # Check if we're at the target key
    if [[ "$line_key" == "$target_key" ]]; then
      # Check if the path matches (either exact match or parent path matches)
      local path_to_check=""
      if [[ ${#parent_keys[@]:-0} -gt 0 ]]; then
        path_to_check=$(IFS='.'; echo "${parent_keys[*]}")
      fi
      
      if [[ ${#parent_keys[@]:-0} -eq 0 ]] || [[ "$current_path" == "$key_path" ]] || [[ -n "$path_to_check" && "$current_path" == "$path_to_check.$target_key" ]]; then
        # Extract value (everything after the colon, remove quotes and comments)
        local value
        value=$(echo "$line" | sed -E 's/^[^:]+:[[:space:]]*//' | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/^["'\''](.*)["'\'']$/\1/' | xargs)
        echo "$value"
        return 0
      fi
    fi
  done < "$CONFIG_FILE"
  
  echo ""
  return 1
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
  
  # Allow access during validation if CONFIG_FILE is set
  if [[ "$CONFIG_LOADED" != "true" ]] && [[ -z "$CONFIG_FILE" ]]; then
    return 1
  fi
  
  # For sections, check if the key exists in the YAML (even if it has no direct value)
  # A section exists if:
  # 1. It has a direct value (not empty, not null)
  # 2. OR it appears as a key with a colon (indicating it's a section/container)
  
  local value
  value=$(get_config_value "$section_path")
  
  # If it has a non-empty, non-null value, it exists
  if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
    return 0
  fi
  
  # Otherwise, check if the key exists in the file (as a section/container)
  if [[ -f "$CONFIG_FILE" ]]; then
    # Convert section path to last key
    local keys
    IFS='.' read -ra keys <<< "$section_path"
    local num_keys=${#keys[@]}
    local section_key="${keys[$((num_keys - 1))]}"
    
    # Check if this key appears in the file (with proper indentation context)
    # This is a simplified check - for full support, yq should be used
    if grep -qE "^[[:space:]]*${section_key}:" "$CONFIG_FILE" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
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
    # Basic array parsing for simple YAML arrays
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo ""
      return 1
    fi
    
    # Find the array section by following the nested structure
    local keys
    IFS='.' read -ra keys <<< "$yaml_path"
    local num_keys=${#keys[@]}
    local array_key="${keys[$((num_keys - 1))]}"
    
    # Build parent keys array
    local parent_keys=()
    local i
    for ((i=0; i<$((num_keys - 1)); i++)); do
      parent_keys+=("${keys[$i]}")
    done
    
    # Find the array section and extract list items
    local in_array=false
    local array_items=()
    local line_num=0
    local indent_stack=()
    local key_stack=()
    local target_array_indent=-1
    
    while IFS= read -r line; do
      line_num=$((line_num + 1))
      
      # Skip comments
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      
      # Get indentation
      local indent=0
      while [[ ${line:$indent:1} == " " ]]; do
        indent=$((indent + 1))
      done
      
      # Extract key from line
      local line_key
      line_key=$(echo "$line" | sed 's/[[:space:]]*\([^:]*\):.*/\1/' | xargs)
      
      # Update stack (same logic as _get_config_value_simple)
      local stack_size=${#indent_stack[@]:-0}
      while [[ $stack_size -gt 0 ]]; do
        local last_indent="${indent_stack[$((stack_size - 1))]}"
        if [[ $last_indent -ge $indent ]]; then
          local new_indent_stack=()
          local new_key_stack=()
          local j
          for ((j=0; j<$((stack_size - 1)); j++)); do
            new_indent_stack+=("${indent_stack[$j]}")
            new_key_stack+=("${key_stack[$j]}")
          done
          if [[ ${#new_indent_stack[@]} -gt 0 ]]; then
            indent_stack=("${new_indent_stack[@]}")
            key_stack=("${new_key_stack[@]}")
          else
            indent_stack=()
            key_stack=()
          fi
          stack_size=${#indent_stack[@]:-0}
        else
          break
        fi
      done
      
      # Build current path from stack
      local current_path=""
      if [[ ${#key_stack[@]:-0} -gt 0 ]]; then
        current_path=$(IFS='.'; echo "${key_stack[*]}")
      fi
      
      # Check if we found the array key with correct parent path
      if [[ "$line_key" == "$array_key" ]] && [[ "$line" =~ :[[:space:]]*$ ]]; then
        # Check if parent path matches
        local path_to_check=""
        if [[ ${#parent_keys[@]:-0} -gt 0 ]]; then
          path_to_check=$(IFS='.'; echo "${parent_keys[*]}")
        fi
        
        if [[ ${#parent_keys[@]:-0} -eq 0 ]] || [[ "$current_path" == "$yaml_path" ]] || [[ -n "$path_to_check" && "$current_path" == "$path_to_check.$array_key" ]]; then
          # This is the array declaration (ends with just colon)
          in_array=true
          target_array_indent=$indent
          continue
        fi
      fi
      
      # If we're in the array, collect list items (lines starting with -)
      if [[ "$in_array" == "true" ]]; then
        # Check if we've moved to a different section (less or equal indentation to array declaration)
        if [[ $indent -le $target_array_indent ]] && [[ ! "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
          # We've moved to a different section
          break
        fi
        
        # Collect list items (lines starting with -)
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
          # Extract the list item value
          local item_value
          item_value=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]*//' | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/^["'\''](.*)["'\'']$/\1/' | xargs)
          if [[ -n "$item_value" ]]; then
            array_items+=("$item_value")
          fi
        fi
      fi
    done < "$CONFIG_FILE"
    
    # Return space-separated list
    if [[ ${#array_items[@]} -gt 0 ]]; then
      echo "${array_items[*]}"
      return 0
    else
      echo ""
      return 1
    fi
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

