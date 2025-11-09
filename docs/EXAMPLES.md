# Configuration Examples

Example configurations for different use cases.

## Minimal Configuration

Perfect for getting started quickly:

```yaml
git:
  user:
    name: "Your Name"
    email: "your.email@example.com"

packages:
  formulae:
    - git
    - vim
  casks:
    - visual-studio-code
```

## Developer Configuration

Comprehensive setup for software development:

```yaml
system:
  preferences:
    dock:
      orientation: "left"
      autohide: true
      tilesize: 36
    finder:
      show_pathbar: true
      show_statusbar: true
      preferred_view: "clmv"
    screenshots:
      location: "~/Documents/Screenshots"
      format: "png"

packages:
  formulae:
    - git
    - vim
    - node
    - python
    - wget
    - curl
    - mas
    - yq
    - zsh-autosuggestions      # Required for shell plugins
    - zsh-syntax-highlighting  # Required for shell plugins
    - powerlevel10k            # Required for shell theme
  casks:
    - visual-studio-code
    - cursor
    - docker
    - iterm2
    - postman
    - 1password
    - 1password-cli

mas:
  apps:
    - id: 1234567890
      name: "Xcode"

direct_downloads:
  - name: "Custom Dev Tool"
    url: "https://example.com/tool.dmg"
    install_method: "dmg"

git:
  user:
    name: "Developer Name"
    email: "developer@example.com"

dotfiles:
  - target: "~/.gitconfig"
    content: |
      [core]
        editor = vim
        autocrlf = input
      [alias]
        st = status
        co = checkout
        br = branch
        ci = commit
        pushf = push --force-with-lease
    backup: true
    mode: "0644"
  
  - target: "~/.vimrc"
    content: |
      set number
      set expandtab
      set tabstop=2
      set shiftwidth=2
      syntax on
      set mouse=a
    backup: true

shell:
  theme: "powerlevel10k"
  plugins:
    - zsh-autosuggestions      # Must be in packages.formulae
    - zsh-syntax-highlighting  # Must be in packages.formulae
    - git                       # Git aliases will be added
  aliases:
    ll: "ls -lah"
    gs: "git status"
    ga: "git add"
    gc: "git commit"
    gp: "git push"
    gpl: "git pull"
    gco: "git checkout"
    gb: "git branch"
    reload: "source ~/.zshrc"
```

## Designer Configuration

Focused on design tools and creative applications:

```yaml
system:
  preferences:
    dock:
      orientation: "left"
      autohide: true
      tilesize: 48
    finder:
      show_pathbar: true
      preferred_view: "icnv"
    screenshots:
      location: "~/Desktop/Screenshots"
      format: "png"

packages:
  formulae:
    - git
    - mas
  casks:
    - figma
    - sketch
    - adobe-creative-cloud
    - 1password
    - google-chrome
    - firefox

mas:
  apps:
    - id: 1234567890
      name: "Design App"
```

## Minimalist Configuration

Minimal setup with essential tools only:

```yaml
git:
  user:
    name: "Your Name"
    email: "your.email@example.com"

packages:
  formulae:
    - git
    - vim
  casks:
    - visual-studio-code

dotfiles:
  - target: "~/.gitconfig"
    content: |
      [core]
        editor = vim
    backup: true
```

## System Administrator Configuration

Comprehensive system management setup:

```yaml
system:
  preferences:
    dock:
      orientation: "bottom"
      autohide: false
      tilesize: 36
    finder:
      show_pathbar: true
      show_statusbar: true
      preferred_view: "clmv"
    screenshots:
      location: "~/Documents/Screenshots"
      format: "png"

packages:
  formulae:
    - git
    - vim
    - wget
    - curl
    - jq
    - yq
    - htop
    - tree
    - mas
  casks:
    - visual-studio-code
    - iterm2
    - 1password
    - 1password-cli
    - docker
    - postman

git:
  user:
    name: "Admin Name"
    email: "admin@example.com"

dotfiles:
  - target: "~/.gitconfig"
    content: |
      [core]
        editor = vim
      [alias]
        st = status
        co = checkout
    backup: true

shell:
  theme: "powerlevel10k"
  plugins:
    - zsh-autosuggestions      # Must be in packages.formulae
    - zsh-syntax-highlighting  # Must be in packages.formulae
    - git                       # Git aliases will be added
  aliases:
    ll: "ls -lah"
    la: "ls -la"
    reload: "source ~/.zshrc"
```

## Security-Focused Configuration

Emphasis on security tools and practices:

```yaml
packages:
  formulae:
    - git
    - vim
    - mas
  casks:
    - 1password
    - 1password-cli
    - visual-studio-code

secrets:
  github_token:
    op_reference: "op://Private/GitHub Token/token"
  api_key:
    op_reference: "op://Work/API Keys/production"

dotfiles:
  - target: "~/.ssh/config"
    content: |
      Host *
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_rsa
    backup: true
    mode: "0600"
```

## Tips for Creating Your Configuration

1. **Start Small**: Begin with a minimal config and add incrementally
2. **Test Incrementally**: Use `--modules` to test individual components
3. **Version Control**: Keep your `config.yaml` in version control (without secrets)
4. **Comments**: Use comments to document your choices
5. **Backup**: The script creates backups, but consider manual backups for important files
6. **Idempotency**: Safe to run multiple times, so experiment freely

## Sharing Configurations

When sharing configurations:
- Remove all secrets and 1Password references
- Remove personal information (names, emails)
- Add comments explaining custom choices
- Include a brief description of the use case

