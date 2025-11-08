# Logging and Progress Reporting Design

## Overview

The logging system provides structured, color-coded output to both log files and STDOUT, with progress bars for long-running operations.

## Log Levels

### DEBUG
- **Purpose**: Detailed diagnostic information for development
- **Output**: Log file only
- **Usage**: Internal function calls, variable states, flow control

### INFO
- **Purpose**: General informational messages
- **Output**: Log file + STDOUT
- **Usage**: Operation start/completion, status updates

### WARN
- **Purpose**: Warning messages for potential issues
- **Output**: Log file + STDOUT (with ⚠️ emoji)
- **Usage**: Non-fatal issues, deprecated features, compatibility warnings

### ERROR
- **Purpose**: Error messages for failed operations
- **Output**: Log file + STDOUT (with ❌ emoji)
- **Usage**: Operation failures, validation errors

### SUCCESS
- **Purpose**: Success confirmation messages
- **Output**: Log file + STDOUT (with ✅ emoji)
- **Usage**: Successful operation completion

## Log File Structure

### File Location
- **Default**: `logs/bootstrap.log`
- **Rotation**: Keep last 10 log files
- **Naming**: `bootstrap.log`, `bootstrap.log.1`, `bootstrap.log.2`, etc.

### Log Entry Format

```
[YYYY-MM-DD HH:MM:SS] [LEVEL] [MODULE] Message
```

Example:
```
[2025-01-27 10:30:15] [INFO] [homebrew] Installing git...
[2025-01-27 10:30:20] [SUCCESS] [homebrew] Installed git
[2025-01-27 10:30:25] [ERROR] [mas] Failed to install app: Authentication required
```

## STDOUT Output

### Color Coding

- **Blue (ℹ️)**: Informational messages
- **Green (✅)**: Success messages
- **Yellow (⚠️)**: Warning messages
- **Red (❌)**: Error messages

### Progress Bars

Progress bars show completion percentage and current operation:

```
┃████████████████████░░░░░░░░░░░░┃  60% Installing visual-studio-code...
```

**Format:**
- Bar width: 30 characters
- Filled: `█` characters
- Empty: `░` characters
- Percentage: Right-aligned 3-digit number
- Message: Current operation description

## Logging API

### Core Functions

```bash
# Initialize logging system
init_logging() {
  # Sets up log file, creates logs directory if needed
  # Returns: 0 on success, 1 on failure
}

# Log messages
log_debug() {
  # Logs DEBUG level message to file only
  # Usage: log_debug "message"
}

log_info() {
  # Logs INFO level message to file and STDOUT
  # Usage: log_info "message"
}

log_warn() {
  # Logs WARN level message to file and STDOUT
  # Usage: log_warn "message"
}

log_error() {
  # Logs ERROR level message to file and STDOUT
  # Usage: log_error "message"
}

log_success() {
  # Logs SUCCESS message to file and STDOUT
  # Usage: log_success "message"
}
```

### Progress Bar Functions

```bash
# Show progress bar
show_progress_bar() {
  # Usage: show_progress_bar <percentage> <message>
  # Example: show_progress_bar 60 "Installing package..."
}

# Clear progress bar (move to new line)
clear_progress_bar() {
  # Clears current line and moves to next
}
```

### Color Management

Colors are defined as ANSI escape codes:

```bash
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'  # No color
readonly BOLD='\033[1m'
```

## Usage Patterns

### Basic Logging

```bash
log_info "Starting package installation..."
if install_package "git"; then
  log_success "Installed git"
else
  log_error "Failed to install git"
  return 1
fi
```

### Progress Reporting

```bash
local total=10
local current=0

for package in "${packages[@]}"; do
  current=$((current + 1))
  local pct=$((current * 100 / total))
  show_progress_bar "$pct" "Installing $package..."
  
  if install_package "$package"; then
    log_success "Installed $package"
  else
    log_error "Failed to install $package"
  fi
done

clear_progress_bar
```

### Module-Specific Logging

```bash
# In module functions, include module name
log_info "[homebrew] Checking if git is installed..."
log_success "[homebrew] git is already installed"
```

## Log Rotation

### Strategy

- Keep last 10 log files
- Rotate on script start (if log file exists and is > 1MB)
- Oldest logs are deleted automatically

### Implementation

```bash
rotate_logs() {
  local log_file="$1"
  local max_logs=10
  
  # Rotate existing logs
  for i in {9..1}; do
    [[ -f "${log_file}.$i" ]] && mv "${log_file}.$i" "${log_file}.$((i+1))"
  done
  
  # Move current log
  [[ -f "$log_file" ]] && mv "$log_file" "${log_file}.1"
}
```

## Error Context

When logging errors, include context:

```bash
log_error "[homebrew] Failed to install $package: $error_message"
log_error "[config] Invalid YAML syntax at line $line_number: $error"
```

## Performance Considerations

- **File I/O**: Logs are written immediately (no buffering)
- **STDOUT**: Only WARN and above go to STDOUT to reduce noise
- **Progress bars**: Updated in-place (no newlines until complete)

## Testing

Logging functions should be testable:
- Mock log file location for testing
- Capture STDOUT for assertion
- Verify log file contents

