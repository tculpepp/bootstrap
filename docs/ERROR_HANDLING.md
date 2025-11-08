# Error Handling Strategy

## Overview

The error handling system provides graceful failure management with user control over error recovery behavior.

## Error Categories

### 1. Non-Fatal Errors
**Behavior**: Log warning, continue execution

**Examples:**
- Package already installed (skip)
- Optional feature unavailable
- Non-critical preference already set

**Pattern:**
```bash
if ! optional_operation; then
  log_warn "Optional operation failed, continuing..."
  # Continue execution
fi
```

### 2. Fatal Errors (Prompt Mode - Default)
**Behavior**: Stop execution, prompt user to continue or abort

**Examples:**
- Network failure during download
- Permission denied for system configuration
- Critical package installation failure
- Configuration validation failure

**Pattern:**
```bash
if ! critical_operation; then
  log_error "Critical operation failed: reason"
  if ! prompt_user "Continue despite error? (y/N)"; then
    exit 1
  fi
fi
```

### 3. Fatal Errors (Auto Mode - with `--continue-on-error`)
**Behavior**: Log error, continue execution, exit with summary

**Examples:**
- Same as Fatal (Prompt), but auto-continues

**Pattern:**
```bash
if ! critical_operation; then
  log_error "Critical operation failed: reason"
  if [[ "${CONTINUE_ON_ERROR:-false}" == "true" ]]; then
    return 1  # Mark as failed but continue
  else
    prompt_user "Continue despite error? (y/N)" || exit 1
  fi
fi
```

## Error Handling Patterns

### Input Validation

```bash
function_name() {
  local arg1="$1"
  local arg2="$2"
  
  # Validate required arguments
  [[ -z "$arg1" ]] && { log_error "arg1 is required"; return 1; }
  [[ -z "$arg2" ]] && { log_error "arg2 is required"; return 1; }
  
  # Validate argument format/type
  [[ ! "$arg1" =~ ^[a-z]+$ ]] && { log_error "arg1 must be lowercase letters only"; return 1; }
  
  # Continue with operation
  # ...
}
```

### Command Execution

```bash
# With error handling
if ! command_to_execute; then
  log_error "Command failed: $(command_to_execute 2>&1)"
  handle_error "command_execution"
  return 1
fi

# With error context
if ! brew install "$package" 2>&1 | tee -a "$LOG_FILE"; then
  log_error "[homebrew] Failed to install $package"
  handle_error "package_installation" "$package"
  return 1
fi
```

### File Operations

```bash
# Check file existence
if [[ ! -f "$file_path" ]]; then
  log_error "File not found: $file_path"
  return 1
fi

# Check write permissions
if [[ ! -w "$(dirname "$file_path")" ]]; then
  log_error "No write permission for directory: $(dirname "$file_path")"
  return 1
fi

# Safe file write
if ! write_file_safely "$file_path" "$content"; then
  log_error "Failed to write file: $file_path"
  return 1
fi
```

### Network Operations

```bash
# Download with retry
download_with_retry() {
  local url="$1"
  local output="$2"
  local max_retries=3
  local retry=0
  
  while [[ $retry -lt $max_retries ]]; do
    if curl -f -L -o "$output" "$url"; then
      return 0
    fi
    retry=$((retry + 1))
    log_warn "Download failed, retry $retry/$max_retries..."
    sleep 2
  done
  
  log_error "Download failed after $max_retries attempts: $url"
  return 1
}
```

## Error Recovery Mechanisms

### State Tracking

Track what has been completed to allow resuming:

```bash
# Check if already done
if check_state "module" "operation"; then
  log_info "Operation already completed, skipping..."
  return 0
fi

# Perform operation
if perform_operation; then
  update_state "module" "operation" "completed"
  return 0
else
  log_error "Operation failed"
  return 1
fi
```

### Backup and Rollback

For destructive operations, create backups:

```bash
backup_file() {
  local file="$1"
  local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
  
  if [[ -f "$file" ]]; then
    cp "$file" "$backup" || {
      log_error "Failed to create backup: $file"
      return 1
    }
    log_info "Backed up $file to $backup"
  fi
}

# Before modifying
backup_file "$target_file" || return 1

# Perform modification
if ! modify_file "$target_file"; then
  log_error "Modification failed, restoring backup..."
  restore_backup "$target_file" || {
    log_error "Failed to restore backup"
    return 1
  }
  return 1
fi
```

### Graceful Degradation

When optional features fail, continue with reduced functionality:

```bash
# Try to use 1Password CLI
if command -v op &> /dev/null && op_account_authenticated; then
  secret=$(op read "$op_reference")
else
  log_warn "1Password CLI not available, prompting for secret..."
  secret=$(prompt_for_secret "Enter secret:")
fi

# Use secret (whether from 1Password or prompt)
use_secret "$secret"
```

## User Interaction Patterns

### Prompt User

```bash
prompt_user() {
  local message="$1"
  local default="${2:-N}"  # Default to "No"
  
  if [[ "${OVERWRITE_MODE:-false}" == "true" ]]; then
    # Auto-accept in overwrite mode
    return 0
  fi
  
  local response
  read -p "$message " response
  response="${response:-$default}"
  
  case "$response" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
```

### Confirmation for Destructive Operations

```bash
if [[ -f "$target_file" ]]; then
  if ! prompt_user "Overwrite existing file $target_file? (y/N)"; then
    log_info "Skipping $target_file (user declined)"
    return 0
  fi
fi
```

## Error Context and Reporting

### Error Messages

Include context in error messages:

```bash
log_error "[module] Operation failed: $operation_name"
log_error "[module] Reason: $error_reason"
log_error "[module] Context: $additional_context"
```

### Error Summary

At script completion, provide error summary:

```bash
summarize_errors() {
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    log_warn "Summary of errors:"
    for error in "${ERRORS[@]}"; do
      log_warn "  - $error"
    done
    return 1
  else
    log_success "All operations completed successfully"
    return 0
  fi
}
```

## Error Handling Best Practices

1. **Validate Early**: Check inputs at function boundaries
2. **Provide Context**: Include relevant information in error messages
3. **Log Everything**: All errors should be logged with appropriate level
4. **User Control**: Give users control over error recovery
5. **State Tracking**: Track what's been done to enable resuming
6. **Backup First**: Create backups before destructive operations
7. **Graceful Degradation**: Continue with reduced functionality when possible
8. **Clear Messages**: Error messages should be clear and actionable

## Testing Error Handling

Test error scenarios:
- Invalid inputs
- Missing dependencies
- Network failures
- Permission errors
- File system errors
- User cancellation

