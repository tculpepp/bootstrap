# Testing Guide

Testing procedures and guidelines for the macOS Configuration Script.

## Table of Contents

- [Testing Strategy](#testing-strategy)
- [Pre-Testing Checklist](#pre-testing-checklist)
- [Testing Scenarios](#testing-scenarios)
- [Module Testing](#module-testing)
- [Integration Testing](#integration-testing)
- [Test Results](#test-results)

## Testing Strategy

### Test Levels

1. **Unit Testing**: Individual module functions
2. **Integration Testing**: Module interactions
3. **System Testing**: End-to-end script execution
4. **User Acceptance Testing**: Real-world usage scenarios

### Test Environments

- **Clean macOS Installation**: Fresh system with minimal configuration
- **Existing macOS System**: System with existing applications and settings
- **Different macOS Versions**: Test compatibility across versions

## Pre-Testing Checklist

Before testing, ensure:

- [ ] macOS 10.15 (Catalina) or later
- [ ] Administrator access available
- [ ] Internet connection active
- [ ] Backup of important data
- [ ] Test system or VM (recommended for clean install testing)
- [ ] Review configuration file
- [ ] Check script permissions (`chmod +x bootstrap.sh`)

## Testing Scenarios

### Scenario 1: Clean macOS Installation

**Purpose**: Test script on a fresh macOS installation

**Steps**:
1. Set up clean macOS installation (VM or test machine)
2. Clone repository
3. Run script:
   ```bash
   ./bootstrap.sh
   ```
4. Verify configuration file is created
5. Customize `config.yaml`
6. Run script again
7. Verify all modules execute successfully

**Expected Results**:
- Configuration file created from example
- All modules execute without errors
- System preferences applied
- Packages installed
- Logs created successfully

**Verification**:
```bash
# Check logs
tail -f logs/bootstrap.log

# Verify system preferences
defaults read com.apple.dock orientation

# Verify packages installed
brew list

# Check dotfiles created
ls -la ~/.gitconfig
```

### Scenario 2: Existing macOS System

**Purpose**: Test script on system with existing applications

**Steps**:
1. On existing macOS system, clone repository
2. Review current system state
3. Create minimal `config.yaml`
4. Run script with specific modules:
   ```bash
   ./bootstrap.sh --modules system
   ```
5. Verify idempotency (run multiple times)
6. Test with `--overwrite` flag
7. Test with `--continue-on-error` flag

**Expected Results**:
- Script detects existing installations
- Idempotent behavior (safe to run multiple times)
- Backups created before modifications
- No duplicate installations

**Verification**:
```bash
# Verify no duplicate packages
brew list | sort | uniq -d

# Check backups created
ls -la ~/.gitconfig.backup.*

# Verify state tracking
cat state/state.json  # If implemented
```

### Scenario 3: Module-Specific Testing

**Purpose**: Test individual modules in isolation

**Steps**:
1. Test each module individually:
   ```bash
   ./bootstrap.sh --modules system
   ./bootstrap.sh --modules homebrew
   ./bootstrap.sh --modules mas
   ./bootstrap.sh --modules direct-download
   ./bootstrap.sh --modules dotfiles
   ./bootstrap.sh --modules shell
   ```

2. Verify each module's functionality
3. Check logs for each module
4. Test error handling

**Expected Results**:
- Each module executes independently
- Proper error handling
- Appropriate logging

### Scenario 4: Error Handling

**Purpose**: Test error handling and recovery

**Steps**:
1. Create invalid configuration (syntax error)
2. Run script and verify error handling
3. Test with missing dependencies
4. Test with network failures (disconnect internet)
5. Test with permission issues
6. Test with `--continue-on-error` flag

**Expected Results**:
- Clear error messages
- Appropriate error recovery
- Script continues or stops appropriately

### Scenario 5: Configuration Validation

**Purpose**: Test configuration validation

**Steps**:
1. Test with invalid YAML
2. Test with invalid values (e.g., invalid dock orientation)
3. Test with missing required fields
4. Test with valid configuration
5. Verify validation messages

**Expected Results**:
- Invalid configurations rejected
- Clear validation error messages
- Valid configurations accepted

## Module Testing

### Logging Module

**Test**: `lib/logging.sh`

```bash
# Source and test
source lib/logging.sh
init_logging
log_info "Test message"
log_success "Success message"
log_error "Error message"
show_progress_bar 50 "Testing..."
clear_progress_bar
```

**Verify**:
- Log file created
- Messages appear in log
- Colors work in terminal
- Progress bars display correctly

### Configuration Module

**Test**: `lib/config.sh`

```bash
source lib/logging.sh
source lib/config.sh
load_config
get_config_value "system.preferences.dock.orientation"
has_config_section "packages"
```

**Verify**:
- Configuration loads correctly
- Values retrieved correctly
- Sections detected correctly
- Validation works

### System Module

**Test**: `lib/system.sh`

```bash
# Test with minimal config
./bootstrap.sh --modules system
```

**Verify**:
- Dock settings applied
- Finder settings applied
- Screenshot settings applied
- Services restarted

### Homebrew Module

**Test**: `lib/homebrew.sh`

```bash
# Test installation
./bootstrap.sh --modules homebrew
```

**Verify**:
- Homebrew installed (if needed)
- Packages installed correctly
- Already-installed packages skipped
- Progress bars work

### Other Modules

Test each module similarly:
- Mac App Store module
- Direct download module
- Dotfiles module
- Shell module
- Secrets module
- Installer module

## Integration Testing

### Full Script Execution

**Test**: Complete script run

```bash
./bootstrap.sh
```

**Verify**:
- All modules execute in order
- Dependencies resolved correctly
- State tracked correctly
- Logs comprehensive

### Module Interactions

**Test**: Module dependencies

```bash
# Test modules that depend on others
./bootstrap.sh --modules mas  # Depends on homebrew
./bootstrap.sh --modules shell  # Depends on homebrew
```

**Verify**:
- Dependencies installed automatically
- Modules work together correctly

## Test Results

### Test Checklist

After testing, verify:

- [ ] All modules execute successfully
- [ ] Configuration file created correctly
- [ ] System preferences applied
- [ ] Packages installed correctly
- [ ] Dotfiles created correctly
- [ ] Shell configuration applied
- [ ] Logs created and readable
- [ ] Error handling works
- [ ] Idempotency verified
- [ ] Backups created
- [ ] Progress bars display
- [ ] Command-line options work

### Known Limitations

- Full YAML array support requires `yq`
- Some modules require manual setup (e.g., MAS sign-in)
- System preferences may require logout/restart
- Network-dependent operations may fail offline

### Test Environment Notes

- Use VM or test machine when possible
- Backup important data before testing
- Test incrementally (one module at a time)
- Review logs after each test
- Document any issues found

## Reporting Test Results

When reporting test results, include:

1. **Environment**:
   - macOS version
   - System type (clean/existing)
   - Hardware (Intel/Apple Silicon)

2. **Configuration**:
   - Config file used (sanitized)
   - Modules tested

3. **Results**:
   - What worked
   - What didn't work
   - Error messages
   - Log excerpts

4. **Reproduction Steps**:
   - Exact commands run
   - Configuration used
   - Expected vs actual behavior

## Continuous Testing

### Before Each Release

- [ ] Test on clean macOS installation
- [ ] Test on existing macOS system
- [ ] Test all modules individually
- [ ] Test error scenarios
- [ ] Verify documentation accuracy
- [ ] Check for regressions

### Automated Testing (Future)

Consider implementing:
- Unit tests for individual functions
- Integration tests for modules
- Configuration validation tests
- Mock system calls for testing

## Best Practices

1. **Test Incrementally**: Start with one module, add more
2. **Use Test Configs**: Create minimal test configurations
3. **Check Logs**: Always review logs after testing
4. **Document Issues**: Keep notes on any problems
5. **Verify State**: Check system state after each test
6. **Clean Up**: Restore system after testing if needed

