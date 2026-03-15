#!/usr/bin/env bash
###############################################################################
#  Module: system.sh
#  Purpose: macOS system preferences configuration
#  Dependencies: logging.sh, config.sh
###############################################################################

set -Eeuo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"
# source "$LIB_DIR/config.sh"

###############################################################################
#  Apply General UI/UX Settings
#  Usage: apply_uiux_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_uiux_settings() {
  # Save to disk (not to iCloud) by default
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false || {
    log_error "[system] Failed to set Save to disk (not to iCloud) by default"
    return 1
  }

  # Automatically quit printer app once the print jobs complete
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true || {
    log_error "[system] Failed to set Automatically quit printer app once the print jobs complete"
    return 1
  }

  # Disable the “Are you sure you want to open this application?” dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false || {
    log_error "[system] Failed to set Disable the “Are you sure you want to open this application?” dialog"
    return 1
  }
  log_success "[system] UI/UX settings applied"
  return 0
}

###############################################################################
#  Apply Trackpad Settings
#  Usage: apply_trackpad_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_trackpad_settings() {
  # Disable “natural” scrolling
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false || {
    log_error "[system] Failed to set Disable natural scrolling"
    return 1
  }

  log_success "[system] Touchpad settings applied"
  return 0
}

###############################################################################
#  Apply Screen Settings
#  Usage: apply_screen_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_screen_settings() {
  # Require password after sleep
  defaults write com.apple.screensaver askForPassword -int 1 || {
    log_error "[system] Failed to set Require password after sleep"
    return 1
  }

  # Password delay to 0
  defaults write com.apple.screensaver askForPasswordDelay -int 0 || {
    log_error "[system] Failed to set password delay to 0"
    return 1
  }

  # Save screenshots to folder
  mkdir -p "${HOME}/Documents/Screenshots"
  defaults write com.apple.screencapture location -string "${HOME}/Documents/Screenshots"

  # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
  defaults write com.apple.screencapture type -string "png"

  # Disable shadow in screenshots
  defaults write com.apple.screencapture disable-shadow -bool true

  # Enable subpixel font rendering on non-Apple LCDs
  # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
  defaults write NSGlobalDomain AppleFontSmoothing -int 1


  log_success "[system] Screen settings applied"
  return 0
}

###############################################################################
#  Apply Finder Settings
#  Usage: apply_trackpad_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_finder_settings() {
  # Finder: show hidden files by default
  #defaults write com.apple.finder AppleShowAllFiles -bool true

  # Finder: show all filename extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Finder: show status bar
  defaults write com.apple.finder ShowStatusBar -bool true

  # Finder: show path bar
  defaults write com.apple.finder ShowPathbar -bool true

  # Display full POSIX path as Finder window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  # Keep folders on top when sorting by name
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Avoid creating .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Use list view in all Finder windows by default
  # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

  # Show the ~/Library folder
  chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

  log_success "[system] Finder settings applied"
  return 0
}

###############################################################################
#  Apply Dock, Dash, hot corner Settings
#  Usage: apply_dock_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_dock_settings() {
  # Set the icon size of Dock items to 36 pixels
  defaults write com.apple.dock tilesize -int 36

  # Wipe all (default) app icons from the Dock
  # This is only really useful when setting up a new Mac, or if you don’t use
  # the Dock to launch apps.
  #defaults write com.apple.dock persistent-apps -array

  # Automatically hide and show the Dock
  defaults write com.apple.dock autohide -bool true

  # Set Dock Orientation/location. Options: "left", "right", "bottom"
  defaults write com.apple.dock orientation -string "left"

  # Dock Magnification
  defaults write com.apple.dock magnification -bool true

  # Only show active apps. Beware this command empties your Dock.
  defaults write com.apple.dock "static-only" -bool "true"

  # Do not display recent apps in the Dock
  defaults write com.apple.dock "show-recents" -bool "false"

  # Don't reorder Spaces based on most recent use
  defaults write com.apple.dock "mru-spaces" -bool "false"

  log_success "[system] Touchpad settings applied"
  return 0
}

###############################################################################
#  Apply spotlight Settings
#  Usage: apply_spotlight_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_spotlight_settings() {
  # disable external suggestions
  defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
  defaults write com.apple.Siri SuggestionsDisabled -bool true
  defaults write com.apple.Siri SiriSuggestionsEnabled -bool false
  defaults write com.apple.assistant.support "Assistant Enabled" -bool false
  killall Spotlight

  # Change indexing order and disable some search results
  defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    '{"enabled" = 1;"name" = "PDF";}' \
    '{"enabled" = 0;"name" = "FONTS";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
  # Load new settings before rebuilding the index
  killall mds > /dev/null 2>&1
  # Make sure indexing is enabled for the main volume
  sudo mdutil -i on / > /dev/null
  # Rebuild the index from scratch
  sudo mdutil -E / > /dev/null

  log_success "[system] Spotlight settings applied"
  return 0
}

###############################################################################
#  Apply activity monitor Settings
#  Usage: apply_activity_monitor_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_activity_monitor_settings() {
  # Show the main window when launching Activity Monitor
  defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

  # Visualize CPU usage in the Activity Monitor Dock icon
  defaults write com.apple.ActivityMonitor IconType -int 5

  # Show all processes in Activity Monitor
  defaults write com.apple.ActivityMonitor ShowCategory -int 0

  # Sort Activity Monitor results by CPU usage
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
  defaults write com.apple.ActivityMonitor SortDirection -int 0

  log_success "[system] Activity Monitor settings applied"
  return 0
}

###############################################################################
#  Apply utility app Settings
#  Usage: apply_app_settings
#  Returns: 0 on success, 1 on failure
###############################################################################

apply_app_settings() {
  # Use plain text mode for new TextEdit documents
  defaults write com.apple.TextEdit RichText -int 0
  # Open and save files as UTF-8 in TextEdit
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

  # Enable the debug menu in Disk Utility
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true

  log_success "[system] Utility App settings applied"
  return 0
}

###############################################################################
#  Restart System Services
#  Usage: restart_system_services [service1] [service2] ...
#  Returns: 0 on success, 1 on failure
###############################################################################

restart_system_services() {
  local services=("$@")
  
  if [[ ${#services[@]} -eq 0 ]]; then
    # Default services to restart
    services=("Dock" "Finder" "cfprefsd" "SystemUIServeer")
  fi
  
  log_info "[system] Restarting system services: ${services[*]}"
  
  local service
  for service in "${services[@]}"; do
    killall "$service" 2>/dev/null || {
      log_warn "[system] Failed to restart $service (may not be running)"
    }
  done
  
  log_success "[system] System services restarted"
  return 0
}

###############################################################################
#  Configure System Preferences
#  Usage: configure_system_preferences
#  Returns: 0 on success, 1 on failure
###############################################################################

configure_system_preferences() {
  log_info "[system] Configuring system preferences..."
  
  local errors=0
  
  apply_uiux_settings || errors=$((errors + 1))
  apply_trackpad_settings || errors=$((errors + 1))
  apply_screen_settings || errors=$((errors + 1))
  apply_finder_settings || errors=$((errors + 1))
  apply_dock_settings || errors=$((errors + 1))
  apply_spotlight_settings || errors=$((errors + 1))
  apply_activity_monitor_settings || errors=$((errors + 1))
  apply_app_settings || errors=$((errors + 1))
  
  # Restart services if any changes were made
  if [[ $errors -eq 0 ]]; then
    restart_system_services "Dock" "Finder" "cfprefsd" "SystemUIServeer"
    log_success "[system] System preferences configured"
    return 0
  else
    log_error "[system] Some system preferences failed to apply"
    return 1
  fi
}

