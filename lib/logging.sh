#!/usr/bin/env bash
###############################################################################
#  Module: logging.sh
#  Purpose: Logging and progress reporting system
#  Dependencies: None (core utility module)
###############################################################################

set -Eeuo pipefail

###############################################################################
#  Color Definitions
###############################################################################

readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'  # No color
readonly BOLD='\033[1m'

###############################################################################
#  Global Variables
###############################################################################

LOG_FILE=""
LOG_DIR=""
BAR_WIDTH=30

###############################################################################
#  Initialize Logging System
#  Usage: init_logging [log_directory] [log_filename]
#  Returns: 0 on success, 1 on failure
###############################################################################

init_logging() {
  local log_dir="${1:-logs}"
  local log_filename="${2:-bootstrap.log}"
  
  # Get script directory (assuming this is called from project root or lib/)
  local script_dir
  if [[ -f "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # If we're in lib/, go up one level
    if [[ "$(basename "$script_dir")" == "lib" ]]; then
      script_dir="$(dirname "$script_dir")"
    fi
  else
    script_dir="$(pwd)"
  fi
  
  LOG_DIR="$script_dir/$log_dir"
  LOG_FILE="$LOG_DIR/$log_filename"
  
  # Create logs directory if it doesn't exist
  if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR" || {
      echo "Failed to create log directory: $LOG_DIR" >&2
      return 1
    }
  fi
  
  # Rotate logs if file exists and is > 1MB
  if [[ -f "$LOG_FILE" ]]; then
    local file_size
    file_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo "0")
    if [[ $file_size -gt 1048576 ]]; then
      rotate_logs "$LOG_FILE"
    fi
  fi
  
  # Initialize log file with header
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] [logging] Logging system initialized" >> "$LOG_FILE"
  
  return 0
}

###############################################################################
#  Rotate Log Files
#  Usage: rotate_logs <log_file>
#  Returns: 0 on success, 1 on failure
###############################################################################

rotate_logs() {
  local log_file="$1"
  local max_logs=10
  
  # Rotate existing logs (9..1)
  local i
  for ((i=9; i>=1; i--)); do
    if [[ -f "${log_file}.${i}" ]]; then
      mv "${log_file}.${i}" "${log_file}.$((i+1))" 2>/dev/null || true
    fi
  done
  
  # Move current log to .1
  if [[ -f "$log_file" ]]; then
    mv "$log_file" "${log_file}.1" || return 1
  fi
  
  return 0
}

###############################################################################
#  Get Timestamp
#  Usage: _get_timestamp
#  Returns: Timestamp string
###############################################################################

_get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

###############################################################################
#  Write to Log File
#  Usage: _write_log <level> <message>
#  Returns: 0 on success, 1 on failure
###############################################################################

_write_log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(_get_timestamp)
  
  if [[ -z "$LOG_FILE" ]]; then
    # If logging not initialized, initialize with defaults
    init_logging || return 1
  fi
  
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE" || return 1
  
  return 0
}

###############################################################################
#  Log Debug Message
#  Usage: log_debug "message"
#  Returns: 0 on success, 1 on failure
###############################################################################

log_debug() {
  local message="$1"
  
  _write_log "DEBUG" "$message" || return 1
  
  return 0
}

###############################################################################
#  Log Info Message
#  Usage: log_info "message"
#  Returns: 0 on success, 1 on failure
###############################################################################

log_info() {
  local message="$1"
  
  _write_log "INFO" "$message" || return 1
  
  # Also output to STDOUT with color
  printf '%sℹ️  %s%s\n' "$BLUE" "$message" "$NC" >&2
  
  return 0
}

###############################################################################
#  Log Warning Message
#  Usage: log_warn "message"
#  Returns: 0 on success, 1 on failure
###############################################################################

log_warn() {
  local message="$1"
  
  _write_log "WARN" "$message" || return 1
  
  # Also output to STDOUT with color
  printf '%s⚠️  %s%s\n' "$YELLOW" "$message" "$NC" >&2
  
  return 0
}

###############################################################################
#  Log Error Message
#  Usage: log_error "message"
#  Returns: 0 on success, 1 on failure
###############################################################################

log_error() {
  local message="$1"
  
  _write_log "ERROR" "$message" || return 1
  
  # Also output to STDOUT with color
  printf '%s❌ %s%s\n' "$RED" "$message" "$NC" >&2
  
  return 0
}

###############################################################################
#  Log Success Message
#  Usage: log_success "message"
#  Returns: 0 on success, 1 on failure
###############################################################################

log_success() {
  local message="$1"
  
  _write_log "SUCCESS" "$message" || return 1
  
  # Also output to STDOUT with color
  printf '%s✅ %s%s\n' "$GREEN" "$message" "$NC" >&2
  
  return 0
}

###############################################################################
#  Show Progress Bar
#  Usage: show_progress_bar <percentage> <message>
#  Returns: 0 on success, 1 on failure
###############################################################################

show_progress_bar() {
  local percentage="$1"
  local message="$2"
  
  # Validate percentage (0-100)
  if [[ $percentage -lt 0 ]]; then
    percentage=0
  elif [[ $percentage -gt 100 ]]; then
    percentage=100
  fi
  
  # Calculate filled and empty spaces
  local done=$((BAR_WIDTH * percentage / 100))
  local todo=$((BAR_WIDTH - done))
  
  # Build progress bar string
  local bar=""
  local i
  for ((i=0; i<done; i++)); do
    bar="${bar}█"
  done
  for ((i=0; i<todo; i++)); do
    bar="${bar}░"
  done
  
  # Print progress bar (no newline, clear line first)
  printf '\r\033[K%s┃%s%s┃ %3d%% %s%s' "$BLUE" "$bar" "$NC" "$percentage" "$message" "$NC" >&2
  
  return 0
}

###############################################################################
#  Clear Progress Bar
#  Usage: clear_progress_bar
#  Returns: 0 on success
###############################################################################

clear_progress_bar() {
  # Clear current line and move to next
  printf '\n' >&2
  
  return 0
}

