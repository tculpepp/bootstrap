#!/usr/bin/env bash
###############################################################################
#  Module: direct-download.sh
#  Purpose: Direct download and installation of applications
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/config.sh"

###############################################################################
#  Download File
#  Usage: download_file <url> <output_path>
#  Returns: 0 on success, 1 on failure
###############################################################################

download_file() {
  local url="$1"
  local output_path="$2"
  
  [[ -z "$url" ]] && { log_error "[direct-download] URL required"; return 1; }
  [[ -z "$output_path" ]] && { log_error "[direct-download] Output path required"; return 1; }
  
  log_info "[direct-download] Downloading from $url..."
  
  # Create output directory if needed
  local output_dir
  output_dir=$(dirname "$output_path")
  if [[ ! -d "$output_dir" ]]; then
    mkdir -p "$output_dir" || {
      log_error "[direct-download] Failed to create output directory: $output_dir"
      return 1
    }
  fi
  
  # Download with curl
  if curl -f -L -o "$output_path" "$url"; then
    log_success "[direct-download] Downloaded to $output_path"
    return 0
  else
    log_error "[direct-download] Download failed: $url"
    return 1
  fi
}

###############################################################################
#  Verify Download Checksum
#  Usage: verify_checksum <file_path> <expected_checksum>
#  Returns: 0 if valid, 1 if invalid
###############################################################################

verify_checksum() {
  local file_path="$1"
  local expected_checksum="$2"
  
  [[ -z "$file_path" ]] && { log_error "[direct-download] File path required"; return 1; }
  [[ -z "$expected_checksum" ]] && { log_warn "[direct-download] No checksum provided, skipping verification"; return 0; }
  
  if [[ ! -f "$file_path" ]]; then
    log_error "[direct-download] File not found: $file_path"
    return 1
  fi
  
  log_info "[direct-download] Verifying checksum..."
  
  local actual_checksum
  actual_checksum=$(shasum -a 256 "$file_path" | cut -d' ' -f1)
  
  if [[ "$actual_checksum" == "$expected_checksum" ]]; then
    log_success "[direct-download] Checksum verified"
    return 0
  else
    log_error "[direct-download] Checksum mismatch. Expected: $expected_checksum, Got: $actual_checksum"
    return 1
  fi
}

###############################################################################
#  Install DMG
#  Usage: install_dmg <dmg_path>
#  Returns: 0 on success, 1 on failure
###############################################################################

install_dmg() {
  local dmg_path="$1"
  
  [[ -z "$dmg_path" ]] && { log_error "[direct-download] DMG path required"; return 1; }
  [[ ! -f "$dmg_path" ]] && { log_error "[direct-download] DMG file not found: $dmg_path"; return 1; }
  
  log_info "[direct-download] Installing DMG: $dmg_path"
  
  # Mount DMG
  local mount_point
  mount_point=$(hdiutil attach "$dmg_path" -nobrowse -quiet | tail -1 | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
  
  if [[ -z "$mount_point" ]]; then
    log_error "[direct-download] Failed to mount DMG"
    return 1
  fi
  
  # Find .app in mounted volume
  local app_path
  app_path=$(find "$mount_point" -name "*.app" -maxdepth 1 | head -1)
  
  if [[ -z "$app_path" ]]; then
    log_error "[direct-download] No .app found in DMG"
    hdiutil detach "$mount_point" -quiet 2>/dev/null || true
    return 1
  fi
  
  # Copy .app to Applications
  local app_name
  app_name=$(basename "$app_path")
  local target_path="/Applications/$app_name"
  
  if [[ -d "$target_path" ]]; then
    log_warn "[direct-download] $app_name already exists in Applications, removing..."
    rm -rf "$target_path" || {
      log_error "[direct-download] Failed to remove existing application"
      hdiutil detach "$mount_point" -quiet 2>/dev/null || true
      return 1
    }
  fi
  
  if cp -R "$app_path" "/Applications/"; then
    log_success "[direct-download] Installed $app_name"
    hdiutil detach "$mount_point" -quiet 2>/dev/null || true
    return 0
  else
    log_error "[direct-download] Failed to copy application"
    hdiutil detach "$mount_point" -quiet 2>/dev/null || true
    return 1
  fi
}

###############################################################################
#  Install PKG
#  Usage: install_pkg <pkg_path>
#  Returns: 0 on success, 1 on failure
###############################################################################

install_pkg() {
  local pkg_path="$1"
  
  [[ -z "$pkg_path" ]] && { log_error "[direct-download] PKG path required"; return 1; }
  [[ ! -f "$pkg_path" ]] && { log_error "[direct-download] PKG file not found: $pkg_path"; return 1; }
  
  log_info "[direct-download] Installing PKG: $pkg_path"
  
  if sudo installer -pkg "$pkg_path" -target /; then
    log_success "[direct-download] Installed PKG: $pkg_path"
    return 0
  else
    log_error "[direct-download] Failed to install PKG: $pkg_path"
    return 1
  fi
}

###############################################################################
#  Extract Archive
#  Usage: extract_archive <archive_path> <output_dir> [format]
#  Returns: 0 on success, 1 on failure
###############################################################################

extract_archive() {
  local archive_path="$1"
  local output_dir="$2"
  local format="${3:-}"
  
  [[ -z "$archive_path" ]] && { log_error "[direct-download] Archive path required"; return 1; }
  [[ -z "$output_dir" ]] && { log_error "[direct-download] Output directory required"; return 1; }
  [[ ! -f "$archive_path" ]] && { log_error "[direct-download] Archive file not found: $archive_path"; return 1; }
  
  # Auto-detect format if not provided
  if [[ -z "$format" ]]; then
    case "$archive_path" in
      *.zip) format="zip" ;;
      *.tar.gz|*.tgz) format="tar.gz" ;;
      *.tar) format="tar" ;;
      *) log_error "[direct-download] Unknown archive format: $archive_path"; return 1 ;;
    esac
  fi
  
  log_info "[direct-download] Extracting $format archive..."
  
  # Create output directory
  mkdir -p "$output_dir" || {
    log_error "[direct-download] Failed to create output directory: $output_dir"
    return 1
  }
  
  # Extract based on format
  case "$format" in
    zip)
      if unzip -q "$archive_path" -d "$output_dir"; then
        log_success "[direct-download] Extracted ZIP archive"
        return 0
      else
        log_error "[direct-download] Failed to extract ZIP archive"
        return 1
      fi
      ;;
    tar|tar.gz|tgz)
      if tar -xzf "$archive_path" -C "$output_dir" 2>/dev/null || tar -xf "$archive_path" -C "$output_dir" 2>/dev/null; then
        log_success "[direct-download] Extracted TAR archive"
        return 0
      else
        log_error "[direct-download] Failed to extract TAR archive"
        return 1
      fi
      ;;
    *)
      log_error "[direct-download] Unsupported archive format: $format"
      return 1
      ;;
  esac
}

###############################################################################
#  Download and Install Application
#  Usage: download_application <name> <url> <install_method> [checksum]
#  Returns: 0 on success, 1 on failure
###############################################################################

download_application() {
  local name="$1"
  local url="$2"
  local install_method="$3"
  local checksum="${4:-}"
  
  [[ -z "$name" ]] && { log_error "[direct-download] Application name required"; return 1; }
  [[ -z "$url" ]] && { log_error "[direct-download] URL required"; return 1; }
  [[ -z "$install_method" ]] && { log_error "[direct-download] Install method required"; return 1; }
  
  log_info "[direct-download] Downloading and installing $name..."
  
  # Create temporary directory
  local temp_dir
  temp_dir=$(mktemp -d)
  local file_path="$temp_dir/$(basename "$url")"
  
  # Download file
  if ! download_file "$url" "$file_path"; then
    rm -rf "$temp_dir"
    return 1
  fi
  
  # Verify checksum if provided
  if [[ -n "$checksum" ]]; then
    if ! verify_checksum "$file_path" "$checksum"; then
      rm -rf "$temp_dir"
      return 1
    fi
  fi
  
  # Install based on method
  local result=0
  case "$install_method" in
    dmg)
      install_dmg "$file_path" || result=1
      ;;
    pkg)
      install_pkg "$file_path" || result=1
      ;;
    zip|tar)
      # For archives, extract and look for .app
      local extract_dir="$temp_dir/extracted"
      if extract_archive "$file_path" "$extract_dir" "$install_method"; then
        local app_path
        app_path=$(find "$extract_dir" -name "*.app" -maxdepth 3 | head -1)
        if [[ -n "$app_path" ]]; then
          local app_name
          app_name=$(basename "$app_path")
          if cp -R "$app_path" "/Applications/"; then
            log_success "[direct-download] Installed $name"
          else
            log_error "[direct-download] Failed to copy application"
            result=1
          fi
        else
          log_error "[direct-download] No .app found in archive"
          result=1
        fi
      else
        result=1
      fi
      ;;
    *)
      log_error "[direct-download] Unknown install method: $install_method"
      result=1
      ;;
  esac
  
  # Cleanup
  rm -rf "$temp_dir"
  
  return $result
}

###############################################################################
#  Install Direct Downloads from Config
#  Usage: install_direct_downloads
#  Returns: 0 on success, 1 on failure
###############################################################################

install_direct_downloads() {
  if ! is_config_loaded; then
    log_error "[direct-download] Configuration not loaded"
    return 1
  fi
  
  # Check if direct_downloads section exists
  if ! has_config_section "direct_downloads"; then
    log_info "[direct-download] No direct downloads configured, skipping..."
    return 0
  fi
  
  # This would require more sophisticated YAML parsing to iterate over array
  # For now, log that this feature needs yq for full support
  if ! command -v yq &> /dev/null; then
    log_warn "[direct-download] Direct downloads require yq for full support. Install yq: brew install yq"
    return 0
  fi
  
  log_info "[direct-download] Processing direct downloads from config..."
  # Implementation would use yq to iterate over direct_downloads array
  # This is a placeholder - full implementation would parse the YAML array
  
  return 0
}

