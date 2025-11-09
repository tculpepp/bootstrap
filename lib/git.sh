#!/usr/bin/env bash
###############################################################################
#  Module: git.sh
#  Purpose: Git configuration (user name and email)
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/config.sh"

###############################################################################
#  Configure Git User
#  Usage: configure_git_user
#  Returns: 0 on success, 1 on failure
###############################################################################

configure_git_user() {
  if ! is_config_loaded; then
    log_error "[git] Configuration not loaded"
    return 1
  fi
  
  # Check if git section exists
  if ! has_config_section "git"; then
    log_info "[git] No git configuration, skipping..."
    return 0
  fi
  
  log_info "[git] Configuring git user settings..."
  
  local git_name
  local git_email
  local errors=0
  
  # Get git configuration from config
  git_name=$(get_config_value "git.user.name" "")
  git_email=$(get_config_value "git.user.email" "")
  
  # Configure user name
  if [[ -n "$git_name" ]]; then
    log_info "[git] Setting user.name to: $git_name"
    if git config --global user.name "$git_name"; then
      log_success "[git] Configured user.name"
    else
      log_error "[git] Failed to configure user.name"
      errors=$((errors + 1))
    fi
  else
    log_warn "[git] git.user.name not specified, skipping..."
  fi
  
  # Configure user email
  if [[ -n "$git_email" ]]; then
    log_info "[git] Setting user.email to: $git_email"
    if git config --global user.email "$git_email"; then
      log_success "[git] Configured user.email"
    else
      log_error "[git] Failed to configure user.email"
      errors=$((errors + 1))
    fi
  else
    log_warn "[git] git.user.email not specified, skipping..."
  fi
  
  if [[ $errors -eq 0 ]]; then
    log_success "[git] Git configuration completed"
    return 0
  else
    log_error "[git] Some git configuration failed"
    return 1
  fi
}

###############################################################################
#  Check if Git is Installed
#  Usage: is_git_installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_git_installed() {
  if command -v git &> /dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Verify Git Configuration
#  Usage: verify_git_config
#  Returns: 0 if configured, 1 if not
###############################################################################

verify_git_config() {
  if ! is_git_installed; then
    log_warn "[git] Git is not installed"
    return 1
  fi
  
  local name
  local email
  
  name=$(git config --global user.name 2>/dev/null || echo "")
  email=$(git config --global user.email 2>/dev/null || echo "")
  
  if [[ -n "$name" ]] && [[ -n "$email" ]]; then
    log_info "[git] Git is configured: $name <$email>"
    return 0
  else
    log_warn "[git] Git is not fully configured"
    [[ -z "$name" ]] && log_warn "[git] user.name is not set"
    [[ -z "$email" ]] && log_warn "[git] user.email is not set"
    return 1
  fi
}

