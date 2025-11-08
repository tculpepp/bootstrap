# Troubleshooting Guide

Common issues and solutions for the macOS Configuration Script.

## Table of Contents

- [Configuration Issues](#configuration-issues)
- [Installation Issues](#installation-issues)
- [Permission Issues](#permission-issues)
- [Network Issues](#network-issues)
- [Module-Specific Issues](#module-specific-issues)
- [Getting Help](#getting-help)

## Configuration Issues

### Configuration File Not Found

**Problem:** Script reports "Configuration file not found"

**Solutions:**
1. The script should automatically create `config.yaml` from `config.yaml.example` on first run
2. If it doesn't, manually copy the example:
   ```bash
   cp config.yaml.example config.yaml
   ```
3. Specify a custom config file:
   ```bash
   ./bootstrap.sh --config /path/to/config.yaml
   ```

### Invalid YAML Syntax

**Problem:** "Invalid YAML syntax" error

**Solutions:**
1. Validate your YAML file:
   ```bash
   # If yq is installed
   yq eval '.' config.yaml
   ```
2. Check for:
   - Missing colons after keys
   - Incorrect indentation (use spaces, not tabs)
   - Unclosed quotes
   - Invalid boolean values (must be `true` or `false`, lowercase)

3. Use an online YAML validator or YAML linter

### Configuration Values Not Applied

**Problem:** Changes in config.yaml don't seem to take effect

**Solutions:**
1. Verify the configuration is loaded:
   - Check logs: `tail logs/bootstrap.log`
   - Look for `[config] Configuration loaded from: ...`

2. Verify the section exists:
   - Check spelling and indentation
   - Ensure proper YAML structure

3. Run the specific module:
   ```bash
   ./bootstrap.sh --modules system
   ```

## Installation Issues

### Homebrew Installation Fails

**Problem:** Homebrew installation fails or times out

**Solutions:**
1. Check internet connection
2. Try manual installation:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. For Apple Silicon Macs, ensure PATH includes `/opt/homebrew/bin`:
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

### Package Installation Fails

**Problem:** Specific packages fail to install

**Solutions:**
1. Check if package name is correct:
   ```bash
   brew search <package-name>
   ```

2. Check Homebrew status:
   ```bash
   brew doctor
   ```

3. Update Homebrew:
   ```bash
   brew update
   ```

4. Check logs for specific error messages:
   ```bash
   grep -i error logs/bootstrap.log
   ```

### Mac App Store Apps Not Installing

**Problem:** MAS apps fail to install

**Solutions:**
1. Ensure you're signed in to Mac App Store:
   ```bash
   mas account
   ```

2. Install MAS CLI if missing:
   ```bash
   brew install mas
   ```

3. Sign in to MAS:
   ```bash
   mas signin <your-apple-id>
   ```

4. Verify App Store ID is correct:
   ```bash
   mas search <app-name>
   ```

### Direct Downloads Fail

**Problem:** Direct download installations fail

**Solutions:**
1. Verify URL is accessible:
   ```bash
   curl -I <url>
   ```

2. Check if checksum is correct (if provided)

3. Verify install method matches file type:
   - `.dmg` files → `install_method: "dmg"`
   - `.pkg` files → `install_method: "pkg"`
   - `.zip` files → `install_method: "zip"`

4. Check disk space:
   ```bash
   df -h
   ```

## Permission Issues

### Permission Denied Errors

**Problem:** "Permission denied" when running script

**Solutions:**
1. Make script executable:
   ```bash
   chmod +x bootstrap.sh
   ```

2. For system preferences, administrator access is required (script will prompt)

3. Check file permissions:
   ```bash
   ls -l bootstrap.sh
   ```

### Cannot Write to Directory

**Problem:** Cannot create files or directories

**Solutions:**
1. Check directory permissions:
   ```bash
   ls -ld <directory>
   ```

2. Ensure you have write access to the script directory

3. For system directories, may require `sudo` (script handles this automatically)

## Network Issues

### Download Timeouts

**Problem:** Downloads timeout or fail

**Solutions:**
1. Check internet connection
2. Verify URLs are correct and accessible
3. Try downloading manually to test:
   ```bash
   curl -O <url>
   ```

4. Check firewall/proxy settings

### Slow Installation

**Problem:** Installation is very slow

**Solutions:**
1. This is normal for large packages or many packages
2. Check network speed
3. Some operations (like Homebrew updates) can be slow
4. Progress bars show current status

## Module-Specific Issues

### System Preferences Not Applied

**Problem:** System preferences don't seem to change

**Solutions:**
1. Some preferences require restarting services:
   - Dock: `killall Dock`
   - Finder: `killall Finder`
   - The script does this automatically

2. Some preferences may require logging out/in or restart

3. Check if preferences are actually set:
   ```bash
   defaults read com.apple.dock orientation
   ```

4. Verify configuration values are correct

### Dotfiles Not Created

**Problem:** Dotfiles aren't being created

**Solutions:**
1. Check if target path is correct (supports `~` expansion)

2. Verify directory exists or can be created:
   ```bash
   mkdir -p $(dirname ~/.config/file)
   ```

3. Check file permissions:
   ```bash
   ls -la ~/.config/file
   ```

4. Review logs for specific errors:
   ```bash
   grep -i dotfile logs/bootstrap.log
   ```

### Shell Configuration Issues

**Problem:** Shell configuration not applied

**Solutions:**
1. Reload shell configuration:
   ```bash
   source ~/.zshrc
   ```

2. Verify `.zshrc` was created/modified:
   ```bash
   ls -la ~/.zshrc
   ```

3. Check for syntax errors in generated `.zshrc`:
   ```bash
   zsh -n ~/.zshrc
   ```

4. Ensure oh-my-zsh or theme is installed if required

### 1Password CLI Issues

**Problem:** Secrets not retrieved from 1Password

**Solutions:**
1. Verify 1Password CLI is installed:
   ```bash
   op --version
   ```

2. Check if authenticated:
   ```bash
   op account list
   ```

3. Sign in if needed:
   ```bash
   op signin
   ```

4. Verify reference format is correct:
   ```
   op://vault/item/field
   ```

5. Test reference manually:
   ```bash
   op read "op://vault/item/field"
   ```

## Getting Help

### Check Logs

Always check logs first:
```bash
# View recent logs
tail -f logs/bootstrap.log

# Search for errors
grep -i error logs/bootstrap.log

# Search for specific module
grep -i "\[module-name\]" logs/bootstrap.log
```

### Enable Debug Logging

Debug logging provides more detail:
- Check logs for `[DEBUG]` entries
- All operations are logged with timestamps

### Common Error Messages

**"Configuration not loaded"**
- Run `load_config()` before accessing config values
- Check if config file exists and is valid

**"Module not found"**
- Verify module file exists in `lib/` directory
- Check module dependencies are loaded

**"Permission denied"**
- Check file permissions
- Ensure script is executable
- May need administrator access for system preferences

### Verification Steps

1. **Verify script is executable:**
   ```bash
   ls -l bootstrap.sh
   ```

2. **Check configuration file:**
   ```bash
   cat config.yaml
   ```

3. **Test individual modules:**
   ```bash
   ./bootstrap.sh --modules system
   ```

4. **Check system requirements:**
   ```bash
   sw_vers  # macOS version
   bash --version  # Bash version
   ```

### Reporting Issues

When reporting issues, include:
1. macOS version: `sw_vers`
2. Error messages from logs
3. Configuration file (sanitized, remove secrets)
4. Steps to reproduce
5. Expected vs actual behavior

## Best Practices

1. **Backup First**: The script creates backups, but consider backing up important files manually
2. **Test Incrementally**: Use `--modules` to test individual components
3. **Review Configuration**: Always review `config.yaml` before running
4. **Check Logs**: Review logs after each run
5. **Version Control**: Keep your `config.yaml` in version control (without secrets)

## Still Having Issues?

1. Review the [User Guide](.conductor/user_guide.md) for detailed usage
2. Check the [Architecture Documentation](.conductor/architecture.md) for technical details
3. Review logs in `logs/bootstrap.log` for specific error messages
4. Verify all prerequisites are met
5. Try running modules individually to isolate the issue

