# Think-Nix

My personal NixOS configuration for a ThinkPad laptop, managed with Nix Flakes.

## 🌟 Features

- **System Configuration**: Managed through NixOS with Flakes for reproducibility
- **Desktop Environment**: KDE Plasma with custom theming and settings
- **User Environment**: Managed by Home Manager
- **Persistence**: Uses Impermanence for state management
- **Development**: Comprehensive development tooling
- **Security**: GPG and SSH agent configuration

## 🖥️ System Configuration

- **Hostname**: `think-nix`
- **Time Zone**: Europe/Bratislava
- **Locale**: en_IE.UTF-8
- **Boot**: systemd-boot with EFI
- **Filesystem**: Btrfs with zstd compression
- **Network**: NetworkManager for network management

## 🔧 Included Components

### System

- KDE Plasma desktop environment
- PipeWire for audio
- Bluetooth support
- Power management with auto-suspend
- Night light with automatic location detection

### Development Tools

- Git with custom configuration
- Neovim as the default editor
- Docker and Podman for containerization
- Various programming language environments
- VS Code with extensions

### Security

- GPG with pinentry
- SSH agent with key management
- Password store integration
- Secure boot configuration

## 🚀 Getting Started

### Prerequisites

- NixOS with Flakes support
- Root access to the system

### Installation

1. Clone this repository to `/etc/nixos`:
   ```bash
   sudo git clone https://github.com/yourusername/think-nix /etc/nixos
   cd /etc/nixos
   ```

2. Build and switch to the new configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#think-nix
   ```

### Home Manager

User-specific packages and configurations are managed by Home Manager, which runs as a NixOS module.
There is no separate `home-manager switch`: `sudo nixos-rebuild switch --flake .#think-nix` applies both.

### AI agents

- [AGENTS.md](AGENTS.md): rules for agents working in this repo.
- [agents/global.md](agents/global.md): user-wide agent instructions. Home Manager symlinks it to
  `~/.config/kilo/AGENTS.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.claude/CLAUDE.md`,
  `~/.pi/agent/AGENTS.md`, and aider's `read:` list.
- [agents/skills/](agents/skills/): on-demand Agent Skills (spec-driven TDD, decision brainstorm, project bootstrap),
  linked to `~/.agents/skills`.
- Global MCP servers (context7, mcp-nixos): `programs.mcp` in `home.nix`.
- Project dev shell scaffold: `nix flake init -t ~/projects/think-nix#devshell`.

### Development

```bash
direnv allow             # or: nix develop  (installs the prek git hook)
prek run --all-files     # gitleaks, nixfmt, deadnix, shellcheck, hygiene
nix fmt                  # format all Nix files
```

CI (`.forgejo/workflows/ci.yml`) runs the same hooks, plus gitleaks over the full history and `nix flake check`.

### Fingerprint for sudo

One-time setup after switching: `fprintd-enroll`, then `fprintd-verify`. Test with `sudo -k && sudo true`.

## 🔄 Maintenance

### Updating the System

To update your system with the latest packages and update all flake inputs:

```bash
nix flake update
sudo nixos-rebuild switch --upgrade --flake .#think-nix
```

This will first update all flake inputs to their latest versions and then apply the system update.

If you only want to update the system without updating the flake inputs, you can use:

```bash
sudo nixos-rebuild switch --upgrade --flake .#think-nix
```

### Garbage Collection

Automatic garbage collection is enabled by default and runs daily, keeping the last 7 days of generations. You can run it manually with:

```bash
sudo nix-collect-garbage --delete-older-than 7d
```

## 📂 Directory Structure

- `flake.nix`: Main flake configuration
- `configuration.nix`: System-wide NixOS configuration
- `home.nix`: User-specific Home Manager configuration
- `hardware-configuration.nix`: Hardware-specific configuration (generated)
- `agents/global.md`: Global AI agent instructions
- `templates/devshell/`: Project dev shell template (flake + direnv)

## 🔗 Useful Resources

### Nix & Nixpkgs
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Core Nix package manager documentation
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Nixpkgs contributor and user guide
- [Nixpkgs GitHub](https://github.com/NixOS/nixpkgs) - Source code and issues
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Great learning resource for Nix
- [Nix.dev](https://nix.dev/) - Opinionated guide for developers

### NixOS Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Great learning resource for Nix
- [NixOS Wiki](https://nixos.wiki/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options Search](https://home-manager-options.extranix.com/) - Search Home Manager options
- [Plasma Manager Options](https://nix-community.github.io/plasma-manager/options.xhtml) - KDE Plasma configuration options

### Package Search
- [NixOS Package Search](https://search.nixos.org/packages) - Official package search
- [NUR Package Search](https://nur.nix-community.org/) - User-contributed packages
- [MyNixOS](https://mynixos.org/) - Search configurations and options

### Community
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Subreddit](https://www.reddit.com/r/NixOS/)
- [NixOS Matrix](https://matrix.to/#/#community:nixos.org) (Chat)

## 🤝 Contributing

This is a personal configuration, but feel free to take inspiration or report issues.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- NixOS community for the amazing distribution
- NUR for additional packages
- All the maintainers of the packages used in this configuration
