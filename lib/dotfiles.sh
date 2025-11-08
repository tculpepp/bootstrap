#!/usr/bin/env bash
###############################################################################
#  Module: dotfiles.sh
#  Purpose: Dotfile configuration management
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"

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
#  Backup Existing File
#  Usage: backup_dotfile <file_path>
#  Returns: Backup file path or empty string on failure
###############################################################################

backup_dotfile() {
  local file_path="$1"
  
  [[ -z "$file_path" ]] && { log_error "[dotfiles] File path required"; echo ""; return; }
  
  if [[ ! -f "$file_path" ]]; then
    # No file to backup
    echo ""
    return 0
  fi
  
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="${file_path}.backup.${timestamp}"
  
  if cp "$file_path" "$backup_path"; then
    log_info "[dotfiles] Backed up $file_path to $backup_path"
    echo "$backup_path"
  else
    log_error "[dotfiles] Failed to backup $file_path"
    echo ""
  fi
}

###############################################################################
#  Set File Permissions
#  Usage: set_dotfile_permissions <file_path> <mode>
#  Returns: 0 on success, 1 on failure
###############################################################################

set_dotfile_permissions() {
  local file_path="$1"
  local mode="${2:-0644}"
  
  [[ -z "$file_path" ]] && { log_error "[dotfiles] File path required"; return 1; }
  [[ ! -f "$file_path" ]] && { log_error "[dotfiles] File not found: $file_path"; return 1; }
  
  if chmod "$mode" "$file_path"; then
    log_debug "[dotfiles] Set permissions $mode on $file_path"
    return 0
  else
    log_error "[dotfiles] Failed to set permissions on $file_path"
    return 1
  fi
}

###############################################################################
#  Create Directory for File
#  Usage: _ensure_directory <file_path>
#  Returns: 0 on success, 1 on failure
###############################################################################

_ensure_directory() {
  local file_path="$1"
  local dir_path
  dir_path=$(dirname "$file_path")
  
  if [[ ! -d "$dir_path" ]]; then
    if mkdir -p "$dir_path"; then
      log_debug "[dotfiles] Created directory: $dir_path"
      return 0
    else
      log_error "[dotfiles] Failed to create directory: $dir_path"
      return 1
    fi
  fi
  
  return 0
}

###############################################################################
#  Copy Dotfile from Source
#  Usage: copy_dotfile_from_source <source_path> <target_path>
#  Returns: 0 on success, 1 on failure
###############################################################################

copy_dotfile_from_source() {
  local source_path="$1"
  local target_path="$2"
  
  [[ -z "$source_path" ]] && { log_error "[dotfiles] Source path required"; return 1; }
  [[ -z "$target_path" ]] && { log_error "[dotfiles] Target path required"; return 1; }
  
  # Expand home directory
  source_path=$(expand_home_path "$source_path")
  target_path=$(expand_home_path "$target_path")
  
  if [[ ! -f "$source_path" ]]; then
    log_error "[dotfiles] Source file not found: $source_path"
    return 1
  fi
  
  # Ensure target directory exists
  if ! _ensure_directory "$target_path"; then
    return 1
  fi
  
  if cp "$source_path" "$target_path"; then
    log_success "[dotfiles] Copied $source_path to $target_path"
    return 0
  else
    log_error "[dotfiles] Failed to copy $source_path to $target_path"
    return 1
  fi
}

###############################################################################
#  Create Dotfile with Content
#  Usage: create_dotfile <target_path> <content> [backup] [mode]
#  Returns: 0 on success, 1 on failure
###############################################################################

create_dotfile() {
  local target_path="$1"
  local content="$2"
  local should_backup="${3:-true}"
  local mode="${4:-0644}"
  
  [[ -z "$target_path" ]] && { log_error "[dotfiles] Target path required"; return 1; }
  
  # Expand home directory
  target_path=$(expand_home_path "$target_path")
  
  # Check if file exists and backup if needed
  if [[ -f "$target_path" ]] && [[ "$should_backup" == "true" ]]; then
    backup_dotfile "$target_path" > /dev/null || {
      log_warn "[dotfiles] Backup failed, but continuing..."
    }
  fi
  
  # Ensure target directory exists
  if ! _ensure_directory "$target_path"; then
    return 1
  fi
  
  # Write content to file
  if echo "$content" > "$target_path"; then
    log_success "[dotfiles] Created $target_path"
    
    # Set permissions
    set_dotfile_permissions "$target_path" "$mode" || return 1
    
    return 0
  else
    log_error "[dotfiles] Failed to create $target_path"
    return 1
  fi
}

###############################################################################
#  Process Dotfiles from Config
#  Usage: process_dotfiles
#  Returns: 0 on success, 1 on failure
###############################################################################

process_dotfiles() {
  if ! is_config_loaded; then
    log_error "[dotfiles] Configuration not loaded"
    return 1
  fi
  
  # Check if dotfiles section exists
  if ! has_config_section "dotfiles"; then
    log_info "[dotfiles] No dotfiles configured, skipping..."
    return 0
  fi
  
  # This would require more sophisticated YAML parsing to iterate over array
  # For now, log that this feature needs yq for full support
  if ! command -v yq &> /dev/null; then
    log_warn "[dotfiles] Dotfiles require yq for full support. Install yq: brew install yq"
    return 0
  fi
  
  log_info "[dotfiles] Processing dotfiles from config..."
  # Implementation would use yq to iterate over dotfiles array
  # This is a placeholder - full implementation would parse the YAML array
  
  return 0
}

