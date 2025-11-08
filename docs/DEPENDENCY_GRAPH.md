# Module Dependency Graph

## Visual Representation

```
bootstrap.sh (Main Entry Point)
│
├── lib/logging.sh (Core - No Dependencies)
│   └── Provides: log_info(), log_error(), log_success(), log_warn(), show_progress_bar()
│
├── lib/config.sh (Core - Depends on: logging.sh)
│   ├── Requires: logging.sh
│   └── Provides: load_config(), get_config_value(), validate_config()
│
├── lib/secrets.sh (Depends on: logging.sh, config.sh)
│   ├── Requires: logging.sh, config.sh
│   └── Provides: get_secret(), setup_1password_cli(), resolve_secret_reference()
│
├── lib/system.sh (Depends on: logging.sh, config.sh)
│   ├── Requires: logging.sh, config.sh
│   └── Provides: configure_system_preferences(), apply_dock_settings(), apply_finder_settings()
│
├── lib/homebrew.sh (Depends on: logging.sh, config.sh)
│   ├── Requires: logging.sh, config.sh
│   └── Provides: install_homebrew(), install_package(), is_package_installed()
│
├── lib/direct-download.sh (Depends on: logging.sh, config.sh)
│   ├── Requires: logging.sh, config.sh
│   └── Provides: download_application(), install_dmg(), install_pkg()
│
├── lib/dotfiles.sh (Depends on: logging.sh, config.sh)
│   ├── Requires: logging.sh, config.sh
│   └── Provides: create_dotfile(), backup_dotfile(), set_dotfile_permissions()
│
├── lib/mas.sh (Depends on: logging.sh, config.sh, homebrew.sh)
│   ├── Requires: logging.sh, config.sh, homebrew.sh
│   └── Provides: install_mas(), install_mas_app(), check_mas_account()
│
├── lib/installer.sh (Depends on: logging.sh, config.sh, homebrew.sh, mas.sh, direct-download.sh)
│   ├── Requires: logging.sh, config.sh, homebrew.sh, mas.sh, direct-download.sh
│   └── Provides: install_application(), determine_installation_source(), try_homebrew_install()
│
└── lib/shell.sh (Depends on: logging.sh, config.sh, homebrew.sh)
    ├── Requires: logging.sh, config.sh, homebrew.sh
    └── Provides: configure_shell(), install_shell_plugins(), generate_zshrc()
```

## Dependency Levels

### Level 0: Core Utilities (No Dependencies)
- `logging.sh`

### Level 1: Configuration (Depends on Level 0)
- `config.sh` → `logging.sh`

### Level 2: Feature Modules (Depends on Level 0-1)
- `secrets.sh` → `logging.sh`, `config.sh`
- `system.sh` → `logging.sh`, `config.sh`
- `homebrew.sh` → `logging.sh`, `config.sh`
- `direct-download.sh` → `logging.sh`, `config.sh`
- `dotfiles.sh` → `logging.sh`, `config.sh`

### Level 3: Advanced Modules (Depends on Level 0-2)
- `mas.sh` → `logging.sh`, `config.sh`, `homebrew.sh`
- `shell.sh` → `logging.sh`, `config.sh`, `homebrew.sh`

### Level 4: Orchestration (Depends on Level 0-3)
- `installer.sh` → `logging.sh`, `config.sh`, `homebrew.sh`, `mas.sh`, `direct-download.sh`

## Loading Order

Modules must be loaded in this order to satisfy dependencies:

1. `logging.sh`
2. `config.sh`
3. `secrets.sh`
4. `system.sh`
5. `homebrew.sh`
6. `direct-download.sh`
7. `dotfiles.sh`
8. `mas.sh`
9. `shell.sh`
10. `installer.sh`

## Circular Dependency Check

✅ **No circular dependencies detected**

The dependency graph is acyclic - all dependencies flow in one direction (from core utilities to orchestration modules).

## Dependency Matrix

| Module | logging | config | secrets | system | homebrew | direct-download | dotfiles | mas | shell | installer |
|--------|---------|--------|---------|--------|----------|----------------|----------|-----|-------|-----------|
| logging | - | - | - | - | - | - | - | - | - | - |
| config | ✓ | - | - | - | - | - | - | - | - | - |
| secrets | ✓ | ✓ | - | - | - | - | - | - | - | - |
| system | ✓ | ✓ | - | - | - | - | - | - | - | - |
| homebrew | ✓ | ✓ | - | - | - | - | - | - | - | - |
| direct-download | ✓ | ✓ | - | - | - | - | - | - | - | - |
| dotfiles | ✓ | ✓ | - | - | - | - | - | - | - | - |
| mas | ✓ | ✓ | - | - | ✓ | - | - | - | - | - |
| shell | ✓ | ✓ | - | - | ✓ | - | - | - | - | - |
| installer | ✓ | ✓ | - | - | ✓ | - | - | ✓ | - | - |

**Legend:**
- `-` = No dependency
- `✓` = Depends on this module

