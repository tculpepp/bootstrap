#!/usr/bin/env bash
###############################################################################
#  Module: system.sh
#  Purpose: macOS system preferences configuration
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"

###############################################################################
#  Apply Dock Settings
#  Usage: apply_dock_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_dock_settings() {
  log_info "[system] Configuring Dock settings..."
  
  local orientation
  local autohide
  local tilesize
  local magnification
  
  # Get dock settings from config
  orientation=$(get_config_value "system.preferences.dock.orientation" "bottom")
  autohide=$(get_config_value "system.preferences.dock.autohide" "false")
  tilesize=$(get_config_value "system.preferences.dock.tilesize" "36")
  magnification=$(get_config_value "system.preferences.dock.magnification" "false")
  
  # Apply orientation
  if [[ -n "$orientation" ]]; then
    defaults write com.apple.dock orientation -string "$orientation" || {
      log_error "[system] Failed to set dock orientation"
      return 1
    }
  fi
  
  # Apply autohide
  if [[ "$autohide" == "true" ]]; then
    defaults write com.apple.dock autohide -bool true || {
      log_error "[system] Failed to set dock autohide"
      return 1
    }
  else
    defaults write com.apple.dock autohide -bool false || {
      log_error "[system] Failed to set dock autohide"
      return 1
    }
  fi
  
  # Apply tilesize
  if [[ -n "$tilesize" ]] && [[ "$tilesize" =~ ^[0-9]+$ ]]; then
    defaults write com.apple.dock tilesize -int "$tilesize" || {
      log_error "[system] Failed to set dock tilesize"
      return 1
    }
  fi
  
  # Apply magnification
  if [[ "$magnification" == "true" ]]; then
    defaults write com.apple.dock magnification -bool true || {
      log_error "[system] Failed to set dock magnification"
      return 1
    }
  else
    defaults write com.apple.dock magnification -bool false || {
      log_error "[system] Failed to set dock magnification"
      return 1
    }
  fi
  
  # Additional dock settings
  defaults write com.apple.dock "static-only" -bool "true" 2>/dev/null || true
  defaults write com.apple.dock "show-recents" -bool "false" 2>/dev/null || true
  defaults write com.apple.dock "mru-spaces" -bool "false" 2>/dev/null || true
  
  log_success "[system] Dock settings applied"
  return 0
}

###############################################################################
#  Apply Finder Settings
#  Usage: apply_finder_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_finder_settings() {
  log_info "[system] Configuring Finder settings..."
  
  local show_pathbar
  local show_statusbar
  local preferred_view
  
  # Get finder settings from config
  show_pathbar=$(get_config_value "system.preferences.finder.show_pathbar" "false")
  show_statusbar=$(get_config_value "system.preferences.finder.show_statusbar" "false")
  preferred_view=$(get_config_value "system.preferences.finder.preferred_view" "icnv")
  
  # Apply pathbar setting
  if [[ "$show_pathbar" == "true" ]]; then
    defaults write com.apple.finder "ShowPathbar" -bool true || {
      log_error "[system] Failed to set finder pathbar"
      return 1
    }
  else
    defaults write com.apple.finder "ShowPathbar" -bool false || {
      log_error "[system] Failed to set finder pathbar"
      return 1
    }
  fi
  
  # Apply statusbar setting
  if [[ "$show_statusbar" == "true" ]]; then
    defaults write com.apple.finder "ShowStatusBar" -bool true || {
      log_error "[system] Failed to set finder statusbar"
      return 1
    }
  else
    defaults write com.apple.finder "ShowStatusBar" -bool false || {
      log_error "[system] Failed to set finder statusbar"
      return 1
    }
  fi
  
  # Apply preferred view
  if [[ -n "$preferred_view" ]]; then
    defaults write com.apple.finder "FXPreferredViewStyle" -string "$preferred_view" || {
      log_error "[system] Failed to set finder preferred view"
      return 1
    }
  fi
  
  # Additional finder settings
  defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true" 2>/dev/null || true
  
  log_success "[system] Finder settings applied"
  return 0
}

###############################################################################
#  Apply Screenshot Settings
#  Usage: apply_screenshot_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_screenshot_settings() {
  log_info "[system] Configuring screenshot settings..."
  
  local location
  local format
  
  # Get screenshot settings from config
  location=$(get_config_value "system.preferences.screenshots.location" "")
  format=$(get_config_value "system.preferences.screenshots.format" "png")
  
  # Apply location
  if [[ -n "$location" ]]; then
    # Expand home directory if needed
    location=$(expand_home_path "$location")
    
    # Create directory if it doesn't exist
    if [[ ! -d "$location" ]]; then
      mkdir -p "$location" || {
        log_error "[system] Failed to create screenshot directory: $location"
        return 1
      }
    fi
    
    defaults write com.apple.screencapture location -string "$location" || {
      log_error "[system] Failed to set screenshot location"
      return 1
    }
  fi
  
  # Apply format
  if [[ -n "$format" ]]; then
    defaults write com.apple.screencapture type -string "$format" || {
      log_error "[system] Failed to set screenshot format"
      return 1
    }
  fi
  
  log_success "[system] Screenshot settings applied"
  return 0
}

###############################################################################
#  Restart System Services
#  Usage: restart_system_services [service1] [service2] ...
#  Returns: 0 on success, 1 on failure
###############################################################################

restart_system_services() {
  local services=("$@")
  
  if [[ ${#services[@]} -eq 0 ]]; then
    # Default services to restart
    services=("Dock" "Finder")
  fi
  
  log_info "[system] Restarting system services: ${services[*]}"
  
  local service
  for service in "${services[@]}"; do
    killall "$service" 2>/dev/null || {
      log_warn "[system] Failed to restart $service (may not be running)"
    }
  done
  
  log_success "[system] System services restarted"
  return 0
}

###############################################################################
#  Configure System Preferences
#  Usage: configure_system_preferences
#  Returns: 0 on success, 1 on failure
###############################################################################

configure_system_preferences() {
  log_info "[system] Configuring system preferences..."
  
  local errors=0
  
  # Check if system preferences section exists
  if ! has_config_section "system.preferences"; then
    log_info "[system] No system preferences configured, skipping..."
    return 0
  fi
  
  # Apply dock settings
  if has_config_section "system.preferences.dock"; then
    apply_dock_settings || errors=$((errors + 1))
  fi
  
  # Apply finder settings
  if has_config_section "system.preferences.finder"; then
    apply_finder_settings || errors=$((errors + 1))
  fi
  
  # Apply screenshot settings
  if has_config_section "system.preferences.screenshots"; then
    apply_screenshot_settings || errors=$((errors + 1))
  fi
  
  # Restart services if any changes were made
  if [[ $errors -eq 0 ]]; then
    restart_system_services "Dock" "Finder"
    log_success "[system] System preferences configured"
    return 0
  else
    log_error "[system] Some system preferences failed to apply"
    return 1
  fi
}

