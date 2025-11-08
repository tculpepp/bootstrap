# Changelog

All notable changes to the macOS Configuration Script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-27

### Added
- Initial release of macOS Configuration Script
- Comprehensive module system for macOS configuration
- System preferences configuration (Dock, Finder, Screenshots)
- Homebrew package management (formulae and casks)
- Mac App Store integration via `mas` CLI
- Direct download installation (DMG, PKG, ZIP, TAR)
- Priority-based installation system (Homebrew → MAS → Direct Download)
- Dotfile management with backup support
- Shell configuration (zsh themes, plugins, aliases)
- 1Password CLI integration for secrets management
- Comprehensive logging system with progress bars
- YAML configuration file support
- Configuration validation and schema checking
- Automatic configuration file initialization
- Command-line interface with module selection
- Error handling with user control
- Idempotent operations (safe to run multiple times)
- Comprehensive documentation (README, User Guide, Troubleshooting, etc.)

### Features
- **Modular Architecture**: 10 core modules with clear dependencies
- **Configuration-Driven**: YAML-based configuration with validation
- **Progress Reporting**: Visual progress bars and detailed logging
- **Error Resilience**: Graceful error handling with user control
- **Portability**: Compatible with stock macOS bash (3.2+)
- **Extensibility**: Easy to add custom modules and functionality

### Documentation
- README.md with quick start guide
- Comprehensive User Guide
- Configuration Schema documentation
- Troubleshooting Guide
- Customization Guide
- Testing Guide
- Architecture documentation

### Technical Details
- Bash 3.2+ compatibility
- macOS 10.15 (Catalina) minimum
- Supports both Intel and Apple Silicon Macs
- Optional yq dependency for full YAML array support

## [Unreleased]

### Planned
- State file management for tracking installation state
- Parallel package installation where safe
- Enhanced YAML parsing without yq dependency
- Additional system preference options
- Plugin system for custom modules
- Automated testing framework

