#!/usr/bin/env bash
###############################################################################
#  Quick Install Script
#  Purpose: Install git (if needed) and clone the macOS Configuration Script
#  Usage: Copy this script, paste it locally, and execute: bash install.sh
###############################################################################

set -euo pipefail

###############################################################################
#  Colors for Output
###############################################################################

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'  # No color

###############################################################################
#  Helper Functions
###############################################################################

print_info() {
  echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warn() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

###############################################################################
#  Check if Git is Installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_git_installed() {
  command -v git &> /dev/null
}

###############################################################################
#  Install Git via Homebrew
#  Returns: 0 on success, 1 on failure
###############################################################################

install_git_homebrew() {
  print_info "Installing git via Homebrew..."
  
  if ! command -v brew &> /dev/null; then
    print_warn "Homebrew is not installed."
    print_info "To install Homebrew, run:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1
  fi
  
  if brew install git; then
    print_info "Git installed successfully!"
    return 0
  else
    print_error "Failed to install git via Homebrew"
    return 1
  fi
}

###############################################################################
#  Install Git
#  Returns: 0 on success, 1 on failure
###############################################################################

install_git() {
  if is_git_installed; then
    print_info "Git is already installed: $(git --version)"
    return 0
  fi
  
  print_warn "Git is not installed."
  echo ""
  print_info "Attempting to install git via Homebrew..."
  
  if install_git_homebrew; then
    return 0
  fi
  
  print_error "Could not install git automatically."
  print_info "Please install git manually:"
  echo "  1. Install Homebrew: https://brew.sh"
  echo "  2. Run: brew install git"
  echo "  3. Or download from: https://git-scm.com/download/mac"
  return 1
}

###############################################################################
#  Prompt for Repository URL
#  Returns: Repository URL or empty string
###############################################################################

prompt_repo_url() {
  local repo_url=""
  
  echo ""
  print_info "Enter the repository URL to clone:"
  echo "  (e.g., https://github.com/username/bootstrap.git)"
  echo ""
  read -p "Repository URL: " repo_url
  
  # Trim whitespace
  repo_url=$(echo "$repo_url" | xargs)
  
  if [[ -z "$repo_url" ]]; then
    print_error "Repository URL cannot be empty"
    return 1
  fi
  
  echo "$repo_url"
  return 0
}

###############################################################################
#  Clone Repository
#  Usage: clone_repo <repo_url> [target_directory]
#  Returns: 0 on success, 1 on failure
###############################################################################

clone_repo() {
  local repo_url="$1"
  local target_dir="${2:-bootstrap}"
  
  if [[ -d "$target_dir" ]]; then
    print_warn "Directory '$target_dir' already exists."
    read -p "Remove it and clone fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      print_info "Removing existing directory..."
      rm -rf "$target_dir"
    else
      print_info "Skipping clone. Using existing directory."
      return 0
    fi
  fi
  
  print_info "Cloning repository..."
  if git clone "$repo_url" "$target_dir"; then
    print_info "Repository cloned successfully to: $target_dir"
    return 0
  else
    print_error "Failed to clone repository"
    return 1
  fi
}

###############################################################################
#  Show Help
###############################################################################

show_help() {
  cat << EOF
macOS Configuration Script - Quick Install

Usage: $0 [REPOSITORY_URL]

Options:
  REPOSITORY_URL    Optional: Repository URL to clone
                    If not provided, you will be prompted

Examples:
  $0
  $0 https://github.com/username/bootstrap.git

EOF
}

###############################################################################
#  Main Execution
###############################################################################

main() {
  local repo_url="${1:-}"
  
  echo "======================================================"
  print_info "macOS Configuration Script - Quick Install"
  echo "======================================================"
  echo ""
  
  # Check macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only"
    exit 1
  fi
  
  # Show help if requested
  if [[ "$repo_url" == "--help" ]] || [[ "$repo_url" == "-h" ]]; then
    show_help
    exit 0
  fi
  
  # Install git if needed
  if ! install_git; then
    print_error "Git installation failed. Please install git manually and try again."
    exit 1
  fi
  
  # Get repository URL (from argument or prompt)
  if [[ -z "$repo_url" ]]; then
    if ! repo_url=$(prompt_repo_url); then
      print_error "Invalid repository URL"
      exit 1
    fi
  fi
  
  # Clone repository
  if ! clone_repo "$repo_url"; then
    print_error "Failed to clone repository"
    exit 1
  fi
  
  # Success message
  echo ""
  echo "======================================================"
  print_info "Installation complete!"
  echo "======================================================"
  echo ""
  print_info "Next steps:"
  echo "  1. cd bootstrap"
  echo "  2. chmod +x bootstrap.sh"
  echo "  3. ./bootstrap.sh"
  echo ""
}

###############################################################################
#  Execute Main
###############################################################################

main "$@"

