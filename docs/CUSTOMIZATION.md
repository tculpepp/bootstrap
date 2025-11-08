# Customization Guide

How to customize the macOS Configuration Script for your specific needs.

## Table of Contents

- [Configuration Customization](#configuration-customization)
- [Adding Custom Modules](#adding-custom-modules)
- [Extending Existing Modules](#extending-existing-modules)
- [Custom Installation Sources](#custom-installation-sources)
- [Advanced Configuration](#advanced-configuration)

## Configuration Customization

### System Preferences

Customize system preferences in `config.yaml`:

```yaml
system:
  preferences:
    dock:
      orientation: "left"      # left, right, or bottom
      autohide: true
      tilesize: 36
      magnification: false
    
    finder:
      show_pathbar: true
      show_statusbar: true
      preferred_view: "clmv"   # clmv, icnv, Nlsv, or Flwv
    
    screenshots:
      location: "~/Documents/Screenshots"
      format: "png"            # png, jpg, or pdf
    
    trackpad:
      natural_scrolling: true  # true = Natural scrolling, false = Traditional scrolling
```

### Adding More System Preferences

To add additional system preferences, extend `lib/system.sh`:

```bash
# In lib/system.sh, add new function:
apply_custom_preference() {
  local key="$1"
  local value="$2"
  defaults write "$key" "$value"
}
```

Then call it from `configure_system_preferences()`.

### Package Selection

Customize packages in `config.yaml`:

```yaml
packages:
  formulae:
    - git
    - vim
    - your-custom-tool
  
  casks:
    - visual-studio-code
    - your-custom-app
```

### Mac App Store Apps

Find App Store IDs and add to config:

```yaml
mas:
  apps:
    - id: 1234567890
      name: "App Name"
```

To find App Store IDs:
```bash
mas search "App Name"
```

### Direct Downloads

Add custom applications:

```yaml
direct_downloads:
  - name: "Custom App"
    url: "https://example.com/app.dmg"
    install_method: "dmg"
    checksum: "sha256_checksum"  # Optional but recommended
```

### Dotfiles

Create custom dotfiles:

```yaml
dotfiles:
  - target: "~/.customrc"
    content: |
      # Your custom configuration
      export CUSTOM_VAR="value"
    backup: true
    mode: "0644"
```

### Shell Configuration

Customize shell setup:

```yaml
shell:
  theme: "powerlevel10k"
  plugins:
    - zsh-autosuggestions
    - zsh-syntax-highlighting
    - your-custom-plugin
  aliases:
    custom: "your-command"
    ll: "ls -lah"
```

## Adding Custom Modules

### Module Structure

Create a new module in `lib/` following the standard structure:

```bash
#!/usr/bin/env bash
###############################################################################
#  Module: custom-module.sh
#  Purpose: Description of what this module does
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/config.sh"

###############################################################################
#  Your Custom Function
#  Usage: custom_function [args]
#  Returns: 0 on success, 1 on failure
###############################################################################

custom_function() {
  local arg1="$1"
  
  [[ -z "$arg1" ]] && { log_error "[custom] arg1 required"; return 1; }
  
  log_info "[custom] Doing something with $arg1"
  
  # Your implementation here
  
  log_success "[custom] Completed"
  return 0
}
```

### Integrating Custom Module

1. **Add to bootstrap.sh:**
   ```bash
   source "$SCRIPT_DIR/lib/custom-module.sh"
   ```

2. **Add to module selection:**
   ```bash
   case "$module_name" in
     custom)
       custom_function
       ;;
   ```

3. **Add configuration section** (if needed):
   ```yaml
   custom:
     setting1: "value"
     setting2: true
   ```

## Extending Existing Modules

### Adding to System Preferences

Extend `lib/system.sh`:

```bash
apply_custom_settings() {
  local setting=$(get_config_value "system.preferences.custom.setting" "default")
  
  defaults write com.apple.custom "Setting" -string "$setting"
  log_success "[system] Applied custom settings"
}
```

### Adding to Homebrew Module

Extend `lib/homebrew.sh`:

```bash
install_custom_packages() {
  local packages
  packages=$(get_config_array "packages.custom")
  
  if [[ -n "$packages" ]]; then
    read -ra package_array <<< "$packages"
    install_packages "formula" "${package_array[@]}"
  fi
}
```

### Adding Installation Methods

Extend `lib/direct-download.sh`:

```bash
install_custom_format() {
  local file_path="$1"
  
  # Your custom installation logic
  # ...
  
  return 0
}
```

Then add to `download_application()`:
```bash
case "$install_method" in
  custom)
    install_custom_format "$file_path" || result=1
    ;;
esac
```

## Custom Installation Sources

### Adding New Priority Level

Modify `lib/installer.sh` to add new installation sources:

```bash
try_custom_source() {
  local app_name="$1"
  
  # Your custom installation logic
  # ...
  
  return 0  # Success
  # return 1  # Failure
}
```

Add to priority order in `determine_installation_source()`:
```bash
# Try custom source
if try_custom_source "$app_name" 2>/dev/null; then
  echo "custom"
  return 0
fi
```

## Advanced Configuration

### Environment Variables

Set environment variables before running:

```bash
export OVERWRITE_MODE=true
export CONTINUE_ON_ERROR=true
./bootstrap.sh
```

### Conditional Execution

Add conditions to modules:

```bash
if [[ "$(get_config_value "feature.enabled" "false")" == "true" ]]; then
  enable_feature
fi
```

### Custom Logging

Add custom log messages:

```bash
log_info "[custom] Custom message"
log_debug "[custom] Debug information"
log_warn "[custom] Warning message"
log_error "[custom] Error message"
log_success "[custom] Success message"
```

### State Management

Track custom state (future feature):

```bash
# In your module
update_state "custom_module" "operation" "completed"
check_state "custom_module" "operation"
```

## Configuration Examples

### Minimal Configuration

```yaml
packages:
  formulae:
    - git
  casks:
    - visual-studio-code
```

### Comprehensive Configuration

See `config.yaml.example` for a complete example with all options.

### Development-Focused

```yaml
packages:
  formulae:
    - git
    - vim
    - node
    - python
  casks:
    - visual-studio-code
    - docker
    - postman

shell:
  theme: "powerlevel10k"
  plugins:
    - git
    - node
    - python
  aliases:
    gs: "git status"
    ga: "git add"
    gc: "git commit"
```

### Designer-Focused

```yaml
packages:
  casks:
    - figma
    - sketch
    - adobe-creative-cloud

system:
  preferences:
    dock:
      orientation: "left"
      autohide: true
```

## Best Practices

1. **Version Control**: Keep your `config.yaml` in version control
2. **Secrets**: Never commit secrets; use 1Password references
3. **Modularity**: Keep customizations in separate modules when possible
4. **Documentation**: Document custom modules and configurations
5. **Testing**: Test customizations incrementally
6. **Backup**: Always backup before major customizations

## Tips

- Use `--modules` to test individual components
- Check logs after each customization
- Start with minimal config and add incrementally
- Use comments in YAML to document choices
- Keep frequently used configs in separate files

## Need Help?

- See [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [User Guide](.conductor/user_guide.md)
- Check [Architecture Documentation](.conductor/architecture.md)

