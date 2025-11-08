#!/usr/bin/env bash
###############################################################################
#  Module: mas.sh
#  Purpose: Mac App Store integration
#  Dependencies: logging.sh, config.sh, homebrew.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/homebrew.sh"

###############################################################################
#  Check if MAS CLI is Installed
#  Usage: is_mas_installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_mas_installed() {
  if command -v mas &> /dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Install MAS CLI
#  Usage: install_mas
#  Returns: 0 on success, 1 on failure
###############################################################################

install_mas() {
  if is_mas_installed; then
    log_info "[mas] MAS CLI is already installed"
    return 0
  fi
  
  log_info "[mas] Installing MAS CLI via Homebrew..."
  
  # Ensure Homebrew is installed
  if ! is_homebrew_installed; then
    install_homebrew || return 1
  fi
  
  # Install mas via Homebrew
  if install_package "mas" "formula"; then
    log_success "[mas] MAS CLI installed"
    return 0
  else
    log_error "[mas] Failed to install MAS CLI"
    return 1
  fi
}

###############################################################################
#  Check MAS Account Status
#  Usage: check_mas_account
#  Returns: 0 if signed in, 1 if not
###############################################################################

check_mas_account() {
  if ! is_mas_installed; then
    log_error "[mas] MAS CLI not installed"
    return 1
  fi
  
  # Check if signed in
  if mas account &> /dev/null; then
    local account
    account=$(mas account 2>/dev/null)
    if [[ -n "$account" ]] && [[ "$account" != "Not signed in" ]]; then
      log_info "[mas] Signed in to Mac App Store as: $account"
      return 0
    else
      log_warn "[mas] Not signed in to Mac App Store"
      return 1
    fi
  else
    log_warn "[mas] Not signed in to Mac App Store"
    return 1
  fi
}

###############################################################################
#  Check if App is Installed
#  Usage: is_mas_app_installed <app_id>
#  Returns: 0 if installed, 1 if not
###############################################################################

is_mas_app_installed() {
  local app_id="$1"
  
  [[ -z "$app_id" ]] && { log_error "[mas] App ID required"; return 1; }
  
  if ! is_mas_installed; then
    return 1
  fi
  
  # Check if app is installed
  if mas list | grep -q "^$app_id "; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Install MAS App
#  Usage: install_mas_app <app_id> [app_name]
#  Returns: 0 on success, 1 on failure
###############################################################################

install_mas_app() {
  local app_id="$1"
  local app_name="${2:-App ID $app_id}"
  
  [[ -z "$app_id" ]] && { log_error "[mas] App ID required"; return 1; }
  
  # Ensure MAS CLI is installed
  if ! is_mas_installed; then
    install_mas || return 1
  fi
  
  # Check if already installed
  if is_mas_app_installed "$app_id"; then
    log_info "[mas] $app_name (ID: $app_id) is already installed"
    return 0
  fi
  
  # Check if signed in
  if ! check_mas_account; then
    log_error "[mas] Must be signed in to Mac App Store to install apps"
    log_info "[mas] Please sign in to the Mac App Store and try again"
    return 1
  fi
  
  log_info "[mas] Installing $app_name (ID: $app_id)..."
  
  if mas install "$app_id"; then
    log_success "[mas] Installed $app_name (ID: $app_id)"
    return 0
  else
    log_error "[mas] Failed to install $app_name (ID: $app_id)"
    return 1
  fi
}

###############################################################################
#  Install MAS Apps from Config
#  Usage: install_mas_apps
#  Returns: 0 on success, 1 on failure
###############################################################################

install_mas_apps() {
  if ! is_config_loaded; then
    log_error "[mas] Configuration not loaded"
    return 1
  fi
  
  # Check if mas section exists
  if ! has_config_section "mas"; then
    log_info "[mas] No Mac App Store apps configured, skipping..."
    return 0
  fi
  
  # Check if apps array exists
  if ! has_config_section "mas.apps"; then
    log_info "[mas] No Mac App Store apps configured, skipping..."
    return 0
  fi
  
  # This would require more sophisticated YAML parsing to iterate over array
  # For now, log that this feature needs yq for full support
  if ! command -v yq &> /dev/null; then
    log_warn "[mas] MAS apps require yq for full support. Install yq: brew install yq"
    return 0
  fi
  
  log_info "[mas] Processing Mac App Store apps from config..."
  # Implementation would use yq to iterate over mas.apps array
  # This is a placeholder - full implementation would parse the YAML array
  
  return 0
}

