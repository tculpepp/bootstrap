#!/usr/bin/env bash
###############################################################################
#  Module: secrets.sh
#  Purpose: 1Password CLI integration for secret management
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/config.sh"

###############################################################################
#  Global Variables
###############################################################################

# Cache for secrets (bash 3.2 compatible - using array instead of associative array)
# Format: Each entry is "key|value"
SECRET_CACHE=()

###############################################################################
#  Get Cached Secret (bash 3.2 compatible)
#  Usage: _get_cached_secret <key>
#  Returns: Cached value or empty string
###############################################################################

_get_cached_secret() {
  local key="$1"
  local entry
  local cached_key
  local cached_value
  
  # Handle empty/unset array (bash 3.2 compatible with set -u)
  if [[ ${#SECRET_CACHE[@]:-0} -eq 0 ]]; then
    echo ""
    return 1
  fi
  
  for entry in "${SECRET_CACHE[@]}"; do
    cached_key="${entry%%|*}"
    if [[ "$cached_key" == "$key" ]]; then
      cached_value="${entry#*|}"
      echo "$cached_value"
      return 0
    fi
  done
  
  echo ""
  return 1
}

###############################################################################
#  Set Cached Secret (bash 3.2 compatible)
#  Usage: _set_cached_secret <key> <value>
#  Returns: 0 on success, 1 on failure
###############################################################################

_set_cached_secret() {
  local key="$1"
  local value="$2"
  local i=0
  local entry
  local cached_key
  local new_cache=()
  
  # Check if key already exists and update it
  local found=0
  if [[ ${#SECRET_CACHE[@]:-0} -gt 0 ]]; then
    for entry in "${SECRET_CACHE[@]}"; do
      cached_key="${entry%%|*}"
      if [[ "$cached_key" == "$key" ]]; then
        new_cache[$i]="$key|$value"
        found=1
      else
        new_cache[$i]="$entry"
      fi
      i=$((i + 1))
    done
  fi
  
  # If key doesn't exist, add it
  if [[ $found -eq 0 ]]; then
    new_cache[$i]="$key|$value"
  fi
  
  # Update the cache array (bash 3.2 compatible)
  SECRET_CACHE=("${new_cache[@]}")
  return 0
}

###############################################################################
#  Check if 1Password CLI is Installed
#  Usage: is_1password_cli_installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_1password_cli_installed() {
  if command -v op &> /dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
#  Check if 1Password CLI is Authenticated
#  Usage: is_1password_authenticated
#  Returns: 0 if authenticated, 1 if not
###############################################################################

is_1password_authenticated() {
  if ! is_1password_cli_installed; then
    return 1
  fi
  
  # Check if signed in
  if op account list &> /dev/null; then
    local accounts
    accounts=$(op account list 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$accounts" -gt 0 ]]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

###############################################################################
#  Setup 1Password CLI
#  Usage: setup_1password_cli
#  Returns: 0 on success, 1 on failure
###############################################################################

setup_1password_cli() {
  if is_1password_cli_installed; then
    log_info "[secrets] 1Password CLI is already installed"
    
    if is_1password_authenticated; then
      log_info "[secrets] 1Password CLI is authenticated"
      return 0
    else
      log_warn "[secrets] 1Password CLI is installed but not authenticated"
      log_info "[secrets] Please run: op signin"
      return 1
    fi
  else
    log_warn "[secrets] 1Password CLI is not installed"
    log_info "[secrets] Install via Homebrew: brew install --cask 1password-cli"
    return 1
  fi
}

###############################################################################
#  Parse 1Password Reference
#  Usage: parse_op_reference <op_reference>
#  Returns: Vault, Item, and Field via global variables or echo
###############################################################################

parse_op_reference() {
  local op_reference="$1"
  
  [[ -z "$op_reference" ]] && { log_error "[secrets] 1Password reference required"; return 1; }
  
  # Format: op://vault/item/field
  if [[ "$op_reference" =~ ^op://([^/]+)/([^/]+)/(.+)$ ]]; then
    local vault="${BASH_REMATCH[1]}"
    local item="${BASH_REMATCH[2]}"
    local field="${BASH_REMATCH[3]}"
    
    echo "$vault|$item|$field"
    return 0
  else
    log_error "[secrets] Invalid 1Password reference format: $op_reference"
    log_error "[secrets] Expected format: op://vault/item/field"
    return 1
  fi
}

###############################################################################
#  Resolve Secret Reference
#  Usage: resolve_secret_reference <op_reference>
#  Returns: Secret value or empty string
###############################################################################

resolve_secret_reference() {
  local op_reference="$1"
  
  [[ -z "$op_reference" ]] && { log_error "[secrets] 1Password reference required"; echo ""; return; }
  
  # Check cache first (bash 3.2 compatible)
  local cached_value
  cached_value=$(_get_cached_secret "$op_reference")
  if [[ -n "$cached_value" ]]; then
    log_debug "[secrets] Using cached secret for: $op_reference"
    echo "$cached_value"
    return 0
  fi
  
  # Check if 1Password CLI is available
  if ! is_1password_cli_installed; then
    log_warn "[secrets] 1Password CLI not installed, cannot retrieve secret"
    echo ""
    return 1
  fi
  
  # Check if authenticated
  if ! is_1password_authenticated; then
    log_warn "[secrets] 1Password CLI not authenticated, cannot retrieve secret"
    echo ""
    return 1
  fi
  
  # Parse reference
  local parsed
  parsed=$(parse_op_reference "$op_reference")
  if [[ $? -ne 0 ]]; then
    echo ""
    return 1
  fi
  
  local vault
  local item
  local field
  IFS='|' read -r vault item field <<< "$parsed"
  
  # Retrieve secret
  log_debug "[secrets] Retrieving secret from 1Password: $vault/$item/$field"
  
  local secret
  secret=$(op read "$op_reference" 2>/dev/null)
  
  if [[ -n "$secret" ]]; then
    # Cache secret (in memory only, bash 3.2 compatible)
    _set_cached_secret "$op_reference" "$secret"
    echo "$secret"
    return 0
  else
    log_error "[secrets] Failed to retrieve secret: $op_reference"
    echo ""
    return 1
  fi
}

###############################################################################
#  Prompt for Secret
#  Usage: prompt_for_secret <prompt_message>
#  Returns: Secret value entered by user
###############################################################################

prompt_for_secret() {
  local prompt_message="${1:-Enter secret:}"
  local secret
  
  read -sp "$prompt_message " secret
  echo "" >&2  # New line after hidden input
  echo "$secret"
}

###############################################################################
#  Get Secret
#  Usage: get_secret <secret_name> [op_reference] [prompt_message]
#  Returns: Secret value or empty string
###############################################################################

get_secret() {
  local secret_name="$1"
  local op_reference="${2:-}"
  local prompt_message="${3:-Enter $secret_name:}"
  
  [[ -z "$secret_name" ]] && { log_error "[secrets] Secret name required"; echo ""; return; }
  
  # Try 1Password first if reference provided
  if [[ -n "$op_reference" ]]; then
    local secret
    secret=$(resolve_secret_reference "$op_reference")
    if [[ -n "$secret" ]]; then
      echo "$secret"
      return 0
    fi
  fi
  
  # Fallback to prompt
  log_warn "[secrets] 1Password secret not available, prompting for $secret_name"
  prompt_for_secret "$prompt_message"
}

###############################################################################
#  Process Secrets from Config
#  Usage: process_secrets
#  Returns: 0 on success, 1 on failure
###############################################################################

process_secrets() {
  if ! is_config_loaded; then
    log_error "[secrets] Configuration not loaded"
    return 1
  fi
  
  # Check if secrets section exists
  if ! has_config_section "secrets"; then
    log_info "[secrets] No secrets configured, skipping..."
    return 0
  fi
  
  # Setup 1Password CLI if needed
  setup_1password_cli || log_warn "[secrets] 1Password CLI not available, secrets will require manual entry"
  
  log_info "[secrets] Secrets configuration processed"
  return 0
}

