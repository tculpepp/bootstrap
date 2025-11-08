#!/usr/bin/env bash
###############################################################################
#  Module: homebrew.sh
#  Purpose: Homebrew package management
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"

###############################################################################
#  Check if Homebrew is Installed
#  Usage: is_homebrew_installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_homebrew_installed() {
  if command -v brew &> /dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Get Homebrew Path
#  Usage: get_homebrew_path
#  Returns: Path to brew executable or empty string
###############################################################################

get_homebrew_path() {
  if is_homebrew_installed; then
    command -v brew
  else
    # Check common installation locations
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      echo "/opt/homebrew/bin/brew"
    elif [[ -f "/usr/local/bin/brew" ]]; then
      echo "/usr/local/bin/brew"
    else
      echo ""
    fi
  fi
}

###############################################################################
#  Install Homebrew
#  Usage: install_homebrew
#  Returns: 0 on success, 1 on failure
###############################################################################

install_homebrew() {
  if is_homebrew_installed; then
    log_info "[homebrew] Homebrew is already installed"
    return 0
  fi
  
  log_info "[homebrew] Installing Homebrew..."
  
  # Install Homebrew using official installer
  if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log_error "[homebrew] Failed to install Homebrew"
    return 1
  fi
  
  # Add Homebrew to PATH if needed (for Apple Silicon)
  if [[ $(uname -m) == "arm64" ]]; then
    local brew_path="/opt/homebrew/bin"
    if [[ ":$PATH:" != *":$brew_path:"* ]]; then
      export PATH="$brew_path:$PATH"
      log_info "[homebrew] Added Homebrew to PATH for Apple Silicon"
    fi
  fi
  
  # Verify installation
  if is_homebrew_installed; then
    log_success "[homebrew] Homebrew installed successfully"
    return 0
  else
    log_error "[homebrew] Homebrew installation completed but brew command not found"
    return 1
  fi
}

###############################################################################
#  Update Homebrew
#  Usage: update_homebrew
#  Returns: 0 on success, 1 on failure
###############################################################################

update_homebrew() {
  if ! is_homebrew_installed; then
    log_warn "[homebrew] Homebrew not installed, skipping update"
    return 0
  fi
  
  log_info "[homebrew] Updating Homebrew..."
  
  if brew update; then
    log_success "[homebrew] Homebrew updated"
    return 0
  else
    log_error "[homebrew] Failed to update Homebrew"
    return 1
  fi
}

###############################################################################
#  Check if Package is Installed
#  Usage: is_package_installed <package_name> [package_type]
#  Returns: 0 if installed, 1 if not
###############################################################################

is_package_installed() {
  local package_name="$1"
  local package_type="${2:-formula}"
  
  [[ -z "$package_name" ]] && { log_error "[homebrew] Package name required"; return 1; }
  
  if ! is_homebrew_installed; then
    return 1
  fi
  
  if [[ "$package_type" == "cask" ]]; then
    brew list --cask "$package_name" &> /dev/null
  else
    brew list "$package_name" &> /dev/null
  fi
}

###############################################################################
#  Install Package
#  Usage: install_package <package_name> [package_type]
#  Returns: 0 on success, 1 on failure
###############################################################################

install_package() {
  local package_name="$1"
  local package_type="${2:-formula}"
  
  [[ -z "$package_name" ]] && { log_error "[homebrew] Package name required"; return 1; }
  
  # Check if already installed
  if is_package_installed "$package_name" "$package_type"; then
    log_info "[homebrew] $package_name ($package_type) is already installed"
    return 0
  fi
  
  # Ensure Homebrew is installed
  if ! is_homebrew_installed; then
    install_homebrew || return 1
  fi
  
  log_info "[homebrew] Installing $package_name ($package_type)..."
  
  if [[ "$package_type" == "cask" ]]; then
    if brew install --cask "$package_name"; then
      log_success "[homebrew] Installed $package_name (cask)"
      return 0
    else
      log_error "[homebrew] Failed to install $package_name (cask)"
      return 1
    fi
  else
    if brew install "$package_name"; then
      log_success "[homebrew] Installed $package_name (formula)"
      return 0
    else
      log_error "[homebrew] Failed to install $package_name (formula)"
      return 1
    fi
  fi
}

###############################################################################
#  Install Multiple Packages
#  Usage: install_packages <package_type> [package1] [package2] ...
#  Returns: 0 on success, 1 on failure
###############################################################################

install_packages() {
  local package_type="$1"
  shift
  local packages=("$@")
  
  [[ -z "$package_type" ]] && { log_error "[homebrew] Package type required"; return 1; }
  [[ ${#packages[@]} -eq 0 ]] && { log_warn "[homebrew] No packages to install"; return 0; }
  
  # Ensure Homebrew is installed
  if ! is_homebrew_installed; then
    install_homebrew || return 1
  fi
  
  log_info "[homebrew] Installing ${#packages[@]} $package_type packages..."
  
  local total=${#packages[@]}
  local current=0
  local errors=0
  
  local package
  for package in "${packages[@]}"; do
    current=$((current + 1))
    local pct=$((current * 100 / total))
    show_progress_bar "$pct" "Installing $package..."
    
    if ! install_package "$package" "$package_type"; then
      errors=$((errors + 1))
    fi
  done
  
  clear_progress_bar
  
  if [[ $errors -eq 0 ]]; then
    log_success "[homebrew] All $package_type packages installed"
    return 0
  else
    log_warn "[homebrew] $errors of ${#packages[@]} $package_type packages failed to install"
    return 1
  fi
}

###############################################################################
#  Install Homebrew Packages from Config
#  Usage: install_homebrew_packages
#  Returns: 0 on success, 1 on failure
###############################################################################

install_homebrew_packages() {
  if ! is_config_loaded; then
    log_error "[homebrew] Configuration not loaded"
    return 1
  fi
  
  # Check if packages section exists
  if ! has_config_section "packages"; then
    log_info "[homebrew] No packages configured, skipping..."
    return 0
  fi
  
  # Install formulae
  if has_config_section "packages.formulae"; then
    local formulae
    formulae=$(get_config_array "packages.formulae")
    if [[ -n "$formulae" ]]; then
      # Convert space-separated string to array
      read -ra formulae_array <<< "$formulae"
      install_packages "formula" "${formulae_array[@]}" || return 1
    fi
  fi
  
  # Install casks
  if has_config_section "packages.casks"; then
    local casks
    casks=$(get_config_array "packages.casks")
    if [[ -n "$casks" ]]; then
      # Convert space-separated string to array
      read -ra casks_array <<< "$casks"
      install_packages "cask" "${casks_array[@]}" || return 1
    fi
  fi
  
  return 0
}

