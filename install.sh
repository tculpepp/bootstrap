#!/usr/bin/env bash
###############################################################################
#  Quick Install Script
#  Purpose: Install Xcode Command Line Tools (includes git) and clone the repo
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
#  Check if Command Line Tools are Installed
#  Returns: 0 if installed, 1 if not
###############################################################################

is_clt_installed() {
  # Check if xcode-select can find the tools
  if xcode-select -p &> /dev/null; then
    return 0
  fi
  
  # Also check if the directory exists
  if [[ -d "/Library/Developer/CommandLineTools" ]]; then
    return 0
  fi
  
  return 1
}

###############################################################################
#  Install Command Line Tools
#  Returns: 0 on success, 1 on failure
###############################################################################

install_clt() {
  print_info "Xcode Command Line Tools are required (includes git and other development tools)"
  echo ""
  print_info "This will open a system dialog to install Command Line Tools."
  print_info "Please complete the installation in the dialog, then return here."
  echo ""
  read -p "Press RETURN to continue or CTRL-C to cancel..."
  
  # Trigger the installation dialog
  print_info "Opening Command Line Tools installation dialog..."
  
  # Check if already installed first
  if is_clt_installed; then
    print_info "Command Line Tools are already installed!"
    return 0
  fi
  
  # Trigger installation (this opens a system dialog)
  # The command returns 0 if dialog was opened, non-zero if already installed or error
  local install_output
  install_output=$(xcode-select --install 2>&1)
  local install_status=$?
  
  # If already installed (shouldn't happen due to check above, but handle anyway)
  if echo "$install_output" | grep -q "already installed" || [[ $install_status -ne 0 ]]; then
    if is_clt_installed; then
      print_info "Command Line Tools are already installed!"
      return 0
    fi
    print_warn "Could not trigger Command Line Tools installation."
    print_info "You may need to install manually: xcode-select --install"
    return 1
  fi
  
  # Wait for installation to complete
  print_info "Waiting for Command Line Tools installation to complete..."
  print_info "This may take several minutes. Please complete the installation in the dialog."
  echo ""
  print_info "Waiting for installation (checking every 5 seconds)..."
  
  # Poll for installation completion
  local max_attempts=60  # 5 minutes max wait
  local attempt=0
  
  while [[ $attempt -lt $max_attempts ]]; do
    if is_clt_installed; then
      echo ""
      print_info "Command Line Tools installation detected!"
      # Give it a moment to fully initialize
      sleep 2
      return 0
    fi
    
    echo -n "."
    sleep 5
    attempt=$((attempt + 1))
  done
  
  echo ""
  print_warn "Installation is taking longer than expected (waited 5 minutes)."
  print_info "The installation may still be in progress."
  print_info "You can:"
  echo "  1. Wait for the installation dialog to complete"
  echo "  2. Run this script again after installation completes"
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  fi
  
  return 1
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
#  Install Git and Command Line Tools
#  Returns: 0 on success, 1 on failure
###############################################################################

install_git() {
  # Check if git is already installed
  if is_git_installed; then
    print_info "Git is already installed: $(git --version)"
    return 0
  fi
  
  print_warn "Git is not installed."
  echo ""
  
  # First, check and install Command Line Tools (which includes git)
  if ! is_clt_installed; then
    print_info "Installing Xcode Command Line Tools (includes git)..."
    if ! install_clt; then
      print_error "Command Line Tools installation failed or was cancelled"
      return 1
    fi
  else
    print_info "Command Line Tools are already installed"
  fi
  
  # Check if git is now available after Command Line Tools installation
  if is_git_installed; then
    print_info "Git is now available: $(git --version)"
    return 0
  fi
  
  # If git is still not available, try Homebrew as fallback
  print_warn "Git is still not available after Command Line Tools installation."
  print_info "Attempting to install git via Homebrew as fallback..."
  
  if install_git_homebrew; then
    return 0
  fi
  
  print_error "Could not install git automatically."
  print_info "Please install git manually:"
  echo "  1. Install Xcode Command Line Tools: xcode-select --install"
  echo "  2. Or install Homebrew: https://brew.sh"
  echo "  3. Then run: brew install git"
  echo "  4. Or download from: https://git-scm.com/download/mac"
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
  echo "  Examples:"
  echo "    https://github.com/username/bootstrap.git"
  echo "    https://github.com/username/bootstrap"
  echo "    git@github.com:username/bootstrap.git"
  echo ""
  read -p "Repository URL: " repo_url
  
  # Trim whitespace (but preserve the URL structure)
  # Use sed instead of xargs to avoid any URL mangling
  repo_url=$(echo "$repo_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
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
  
  # Debug: Verify URL was received
  if [[ -z "$repo_url" ]]; then
    print_error "clone_repo() received empty URL"
    return 1
  fi
  
  # Validate that git is available
  if ! is_git_installed; then
    print_error "Git is not available. Cannot clone repository."
    return 1
  fi
  
  # Basic URL validation
  if [[ -z "$repo_url" ]]; then
    print_error "Repository URL is empty"
    return 1
  fi
  
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
  
  # Ensure URL is properly quoted and doesn't have extra whitespace
  repo_url=$(echo "$repo_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  # Validate URL is not empty after trimming
  if [[ -z "$repo_url" ]]; then
    print_error "Repository URL is empty after processing"
    return 1
  fi
  
  # Debug: Show what we're about to clone
  print_info "Cloning repository from: $repo_url"
  print_info "Target directory: $target_dir"
  echo ""
  
  # Show the exact command that will be run (using printf for safety)
  print_info "Executing git command:"
  printf "  git clone %q %q\n" "$repo_url" "$target_dir"
  echo ""
  
  # Capture git clone output and error
  local clone_output
  local clone_status=0
  
  # Run git clone and capture both output and exit status
  # Temporarily disable strict error handling to capture status
  set +e  # Disable exit on error
  set +o pipefail  # Disable pipefail
  clone_output=$(git clone "$repo_url" "$target_dir" 2>&1)
  clone_status=$?
  set -e  # Re-enable exit on error
  set -o pipefail  # Re-enable pipefail
  
  if [[ $clone_status -eq 0 ]]; then
    print_info "Repository cloned successfully to: $target_dir"
    return 0
  else
    echo ""
    print_error "Failed to clone repository (exit code: $clone_status)"
    echo ""
    print_info "Command that failed:"
    echo "  git clone \"$repo_url\" \"$target_dir\""
    echo ""
    print_info "URL that was used:"
    echo "  '$repo_url'"
    echo ""
    print_info "Git error output:"
    echo "$clone_output" | sed 's/^/  /'
    echo ""
    
    # Provide helpful troubleshooting based on common errors
    if echo "$clone_output" | grep -qi "could not resolve host"; then
      print_error "Network error: Could not reach the repository host"
      print_info "Check your internet connection and try again"
    elif echo "$clone_output" | grep -qi "permission denied"; then
      print_error "Permission denied"
      print_info "If this is a private repository, you may need to:"
      echo "  - Use SSH authentication (git@github.com:user/repo.git)"
      echo "  - Configure git credentials for HTTPS"
      echo "  - Use a personal access token for HTTPS"
    elif echo "$clone_output" | grep -qi "repository not found"; then
      print_error "Repository not found"
      print_info "Please verify:"
      echo "  - The repository URL is correct"
      echo "  - The repository exists and is accessible"
      echo "  - You have permission to access the repository"
    elif echo "$clone_output" | grep -qi "fatal: not a git repository"; then
      print_error "Invalid repository URL"
      print_info "The URL does not appear to be a valid git repository"
    else
      print_info "Troubleshooting tips:"
      echo "  - Verify the repository URL is correct"
      echo "  - Check your internet connection"
      echo "  - For private repos, ensure you're authenticated"
      echo "  - Try cloning manually: git clone $repo_url"
    fi
    
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
  $0 https://github.com/username/bootstrap
  $0 git@github.com:username/bootstrap.git

Repository URL Formats Supported:
  - HTTPS: https://github.com/username/repo.git
  - HTTPS (no .git): https://github.com/username/repo
  - SSH: git@github.com:username/repo.git
  - Any format accepted by 'git clone'

EOF
}

###############################################################################
#  Main Execution
###############################################################################

main() {
  # Capture all arguments to preserve URL if it contains spaces or special chars
  local repo_url=""
  
  # If first argument is help flag, show help
  if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
  fi
  
  # If first argument exists and is not empty, use it as URL
  # Join all arguments in case URL was split (shouldn't happen with proper quoting, but be safe)
  if [[ $# -gt 0 ]]; then
    repo_url="$*"
  fi
  
  echo "======================================================"
  print_info "macOS Configuration Script - Quick Install"
  echo "======================================================"
  echo ""
  
  # Check macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only"
    exit 1
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
  
  # Trim any extra whitespace from URL
  repo_url=$(echo "$repo_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  # Debug: Show URL before passing to clone function
  if [[ -z "$repo_url" ]]; then
    print_error "Repository URL is empty"
    exit 1
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

