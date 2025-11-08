#!/usr/bin/env bash
###############################################################################
#  Module: installer.sh
#  Purpose: Priority-based installation coordination
#  Dependencies: logging.sh, config.sh, homebrew.sh, mas.sh, direct-download.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/homebrew.sh"
source "$SCRIPT_DIR/mas.sh"
source "$SCRIPT_DIR/direct-download.sh"

###############################################################################
#  Try Homebrew Installation
#  Usage: try_homebrew_install <app_name>
#  Returns: 0 on success, 1 on failure
###############################################################################

try_homebrew_install() {
  local app_name="$1"
  
  [[ -z "$app_name" ]] && { log_error "[installer] App name required"; return 1; }
  
  if ! is_homebrew_installed; then
    return 1
  fi
  
  # Check if available as formula
  if brew search --formulae "^${app_name}$" &> /dev/null; then
    log_info "[installer] Found $app_name as Homebrew formula"
    if install_package "$app_name" "formula"; then
      return 0
    fi
  fi
  
  # Check if available as cask
  if brew search --casks "^${app_name}$" &> /dev/null; then
    log_info "[installer] Found $app_name as Homebrew cask"
    if install_package "$app_name" "cask"; then
      return 0
    fi
  fi
  
  return 1
}

###############################################################################
#  Try Mac App Store Installation
#  Usage: try_mas_install <app_name>
#  Returns: 0 on success, 1 on failure
###############################################################################

try_mas_install() {
  local app_name="$1"
  
  [[ -z "$app_name" ]] && { log_error "[installer] App name required"; return 1; }
  
  if ! is_mas_installed; then
    return 1
  fi
  
  # Search Mac App Store
  log_debug "[installer] Searching Mac App Store for: $app_name"
  
  # MAS search is limited, so this is a simplified implementation
  # In practice, you'd need the App Store ID from config
  log_warn "[installer] MAS installation requires App Store ID from config"
  return 1
}

###############################################################################
#  Try Direct Download Installation
#  Usage: try_direct_download <app_name>
#  Returns: 0 on success, 1 on failure
###############################################################################

try_direct_download() {
  local app_name="$1"
  
  [[ -z "$app_name" ]] && { log_error "[installer] App name required"; return 1; }
  
  if ! is_config_loaded; then
    return 1
  fi
  
  # Check if app is in direct_downloads config
  # This would require yq to search the array
  if ! command -v yq &> /dev/null; then
    return 1
  fi
  
  # Search for app in direct_downloads
  local url
  url=$(yq eval ".direct_downloads[] | select(.name == \"$app_name\") | .url" "$(get_config_file_path)" 2>/dev/null)
  
  if [[ -n "$url" ]]; then
    local install_method
    install_method=$(yq eval ".direct_downloads[] | select(.name == \"$app_name\") | .install_method" "$(get_config_file_path)" 2>/dev/null)
    local checksum
    checksum=$(yq eval ".direct_downloads[] | select(.name == \"$app_name\") | .checksum // \"\"" "$(get_config_file_path)" 2>/dev/null)
    
    log_info "[installer] Found $app_name in direct downloads"
    if download_application "$app_name" "$url" "$install_method" "$checksum"; then
      return 0
    fi
  fi
  
  return 1
}

###############################################################################
#  Determine Installation Source
#  Usage: determine_installation_source <app_name>
#  Returns: "homebrew", "mas", "direct", or "none"
###############################################################################

determine_installation_source() {
  local app_name="$1"
  
  [[ -z "$app_name" ]] && { log_error "[installer] App name required"; echo "none"; return; }
  
  # Try in priority order: Homebrew → MAS → Direct Download
  if try_homebrew_install "$app_name" 2>/dev/null; then
    echo "homebrew"
    return 0
  fi
  
  if try_mas_install "$app_name" 2>/dev/null; then
    echo "mas"
    return 0
  fi
  
  if try_direct_download "$app_name" 2>/dev/null; then
    echo "direct"
    return 0
  fi
  
  echo "none"
  return 1
}

###############################################################################
#  Install Application (Priority-Based)
#  Usage: install_application <app_name>
#  Returns: 0 on success, 1 on failure
###############################################################################

install_application() {
  local app_name="$1"
  
  [[ -z "$app_name" ]] && { log_error "[installer] App name required"; return 1; }
  
  log_info "[installer] Installing $app_name (trying sources in priority order)..."
  
  local source
  source=$(determine_installation_source "$app_name")
  
  case "$source" in
    homebrew)
      log_success "[installer] Installed $app_name via Homebrew"
      return 0
      ;;
    mas)
      log_success "[installer] Installed $app_name via Mac App Store"
      return 0
      ;;
    direct)
      log_success "[installer] Installed $app_name via direct download"
      return 0
      ;;
    none)
      log_error "[installer] Could not install $app_name from any source"
      return 1
      ;;
    *)
      log_error "[installer] Unknown installation source: $source"
      return 1
      ;;
  esac
}

###############################################################################
#  Install Applications from Config
#  Usage: install_applications
#  Returns: 0 on success, 1 on failure
###############################################################################

install_applications() {
  if ! is_config_loaded; then
    log_error "[installer] Configuration not loaded"
    return 1
  fi
  
  log_info "[installer] Installing applications using priority-based source selection..."
  
  # Install Homebrew packages first (they're explicitly configured)
  if has_config_section "packages"; then
    install_homebrew_packages || log_warn "[installer] Some Homebrew packages failed to install"
  fi
  
  # Install Mac App Store apps
  if has_config_section "mas"; then
    install_mas_apps || log_warn "[installer] Some Mac App Store apps failed to install"
  fi
  
  # Install direct downloads
  if has_config_section "direct_downloads"; then
    install_direct_downloads || log_warn "[installer] Some direct downloads failed to install"
  fi
  
  log_success "[installer] Application installation completed"
  return 0
}

