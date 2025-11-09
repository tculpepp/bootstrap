#!/usr/bin/env bash
###############################################################################
#  macOS Configuration Script
#  Purpose: Automated macOS system configuration and application installation
#  Usage: ./bootstrap.sh [options]
#  Version: 1.0.0
###############################################################################

set -Eeuo pipefail

###############################################################################
#  Global Variables
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE=""
OVERWRITE_MODE=false
CONTINUE_ON_ERROR=false
MODULES=""
LOG_DIR="$SCRIPT_DIR/logs"

###############################################################################
#  Source Core Modules
###############################################################################

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/homebrew.sh"
source "$SCRIPT_DIR/lib/secrets.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/mas.sh"
source "$SCRIPT_DIR/lib/direct-download.sh"
source "$SCRIPT_DIR/lib/dotfiles.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/installer.sh"

###############################################################################
#  Show Help
#  Usage: show_help
###############################################################################

show_help() {
  cat << EOF
macOS Configuration Script

Usage: $0 [OPTIONS]

Options:
  --config <path>          Specify configuration file (default: config.yaml)
  --overwrite              Automatically overwrite existing configurations
  --continue-on-error      Continue execution even if a step fails
  --modules <list>         Run only specific modules (comma-separated)
                           Available: system,homebrew,mas,direct-download,dotfiles,git,shell
  --help                   Show this help message

Examples:
  $0
  $0 --config ~/my-config.yaml
  $0 --modules system,homebrew
  $0 --overwrite --continue-on-error

EOF
}

###############################################################################
#  Parse Command-Line Arguments
#  Usage: parse_arguments [args...]
###############################################################################

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      --overwrite)
        OVERWRITE_MODE=true
        shift
        ;;
      --continue-on-error)
        CONTINUE_ON_ERROR=true
        shift
        ;;
      --modules)
        MODULES="$2"
        shift 2
        ;;
      --help)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

###############################################################################
#  Check macOS Version
#  Usage: check_macos_version
#  Returns: 0 if compatible, 1 if not
###############################################################################

check_macos_version() {
  local version
  version=$(sw_vers -productVersion)
  local major
  major=$(echo "$version" | cut -d. -f1)
  local minor
  minor=$(echo "$version" | cut -d. -f2)
  
  log_info "macOS version: $version"
  
  # Check minimum version (macOS 10.15 Catalina)
  if [[ $major -lt 10 ]] || [[ $major -eq 10 && $minor -lt 15 ]]; then
    log_warn "macOS version $version may not be fully supported (minimum: 10.15)"
    return 1
  fi
  
  return 0
}

###############################################################################
#  Welcome Message
#  Usage: show_welcome
###############################################################################

show_welcome() {
  local version
  if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    version=$(cat "$SCRIPT_DIR/VERSION")
  else
    version="dev"
  fi
  
  echo "======================================================"
  log_info "macOS Configuration Script v${version}"
  echo "======================================================"
  echo ""
}

###############################################################################
#  Setup Prerequisites
#  Installs Homebrew and yq if not already installed
#  Usage: setup_prerequisites
#  Returns: 0 on success, 1 on failure
###############################################################################

setup_prerequisites() {
  log_info "Setting up prerequisites (Homebrew and yq)..."
  
  # Install Homebrew if not installed
  if ! command -v brew &> /dev/null; then
    log_info "Homebrew not found. Installing Homebrew..."
    if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      log_error "Failed to install Homebrew"
      return 1
    fi
    
    # Add Homebrew to PATH if needed (for Apple Silicon)
    if [[ $(uname -m) == "arm64" ]]; then
      local brew_path="/opt/homebrew/bin"
      if [[ ":$PATH:" != *":$brew_path:"* ]]; then
        export PATH="$brew_path:$PATH"
        log_info "Added Homebrew to PATH for Apple Silicon"
      fi
    fi
    
    # Verify Homebrew installation
    if ! command -v brew &> /dev/null; then
      log_error "Homebrew installation completed but brew command not found"
      log_info "You may need to restart your terminal or run: eval \"\$(/opt/homebrew/bin/brew shellenv)\""
      return 1
    fi
    
    log_success "Homebrew installed successfully"
  else
    log_info "Homebrew is already installed"
  fi
  
  # Install yq if not installed
  if ! command -v yq &> /dev/null; then
    log_info "yq not found. Installing yq via Homebrew..."
    if brew install yq; then
      log_success "yq installed successfully"
    else
      log_warn "Failed to install yq. Config parsing will use basic parser (limited functionality)"
      return 0  # Don't fail if yq installation fails, just warn
    fi
  else
    log_info "yq is already installed"
  fi
  
  log_success "Prerequisites setup completed"
  return 0
}

###############################################################################
#  Run Module
#  Usage: run_module <module_name>
#  Returns: 0 on success, 1 on failure
###############################################################################

run_module() {
  local module_name="$1"
  
  case "$module_name" in
    system)
      configure_system_preferences
      ;;
    homebrew)
      install_homebrew_packages
      ;;
    mas)
      install_mas_apps
      ;;
    direct-download)
      install_direct_downloads
      ;;
    dotfiles)
      process_dotfiles
      ;;
    shell)
      configure_shell
      ;;
    git)
      configure_git_user
      ;;
    *)
      log_warn "Unknown module: $module_name"
      return 1
      ;;
  esac
}

###############################################################################
#  Main Execution
###############################################################################

main() {
  # Parse arguments
  parse_arguments "$@"
  
  # Show welcome
  show_welcome
  
  # Initialize logging
  if ! init_logging "$LOG_DIR"; then
    echo "Failed to initialize logging system" >&2
    exit 1
  fi
  
  log_info "Starting macOS configuration script"
  
  # Check macOS version
  check_macos_version || {
    if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
      log_error "Unsupported macOS version. Use --continue-on-error to proceed anyway."
      exit 1
    fi
  }
  
  # Setup prerequisites (Homebrew and yq) before loading config
  if ! setup_prerequisites; then
    log_error "Failed to setup prerequisites"
    if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
      exit 1
    fi
    log_warn "Continuing despite prerequisite setup issues..."
  fi
  
  # Load configuration
  if ! load_config "$CONFIG_FILE"; then
    # Try to initialize from example if config doesn't exist
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local default_config="$script_dir/config.yaml"
    local example_config="$script_dir/config.yaml.example"
    
    if [[ ! -f "$default_config" ]] && [[ -f "$example_config" ]]; then
      log_info "Configuration file not found. Creating from example..."
      if init_config_file "$default_config" "$example_config"; then
        log_info "Please review and customize $default_config, then run again."
        exit 0
      fi
    fi
    
    log_error "Failed to load configuration file"
    log_info "Please create a config.yaml file or specify one with --config"
    exit 1
  fi
  
  # Process secrets (early, as other modules may need them)
  process_secrets || log_warn "Secrets processing had issues"
  
  # Determine which modules to run
  if [[ -n "$MODULES" ]]; then
    # Run specified modules
    IFS=',' read -ra module_array <<< "$MODULES"
    for module in "${module_array[@]}"; do
      module=$(echo "$module" | tr -d ' ')
      log_info "Running module: $module"
      if ! run_module "$module"; then
        if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
          log_error "Module $module failed. Use --continue-on-error to continue."
          exit 1
        fi
      fi
    done
  else
    # Run all modules in order
    log_info "Running all modules..."
    
    # System preferences
    if ! configure_system_preferences; then
      [[ "$CONTINUE_ON_ERROR" != "true" ]] && exit 1
    fi
    
    # Application installation (priority-based)
    if ! install_applications; then
      [[ "$CONTINUE_ON_ERROR" != "true" ]] && exit 1
    fi
    
    # Dotfiles
    if ! process_dotfiles; then
      [[ "$CONTINUE_ON_ERROR" != "true" ]] && exit 1
    fi
    
    # Git configuration
    if ! configure_git_user; then
      [[ "$CONTINUE_ON_ERROR" != "true" ]] && exit 1
    fi
    
    # Shell configuration
    if ! configure_shell; then
      [[ "$CONTINUE_ON_ERROR" != "true" ]] && exit 1
    fi
  fi
  
  log_success "macOS configuration completed!"
  log_info "Check logs at: $LOG_FILE"
  
  return 0
}

###############################################################################
#  Execute Main
###############################################################################

main "$@"

