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

User-specific packages and configurations are managed by Home Manager. After the initial system setup, apply the home configuration:

```bash
home-manager switch --flake .#koyuch@think-nix
```

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

## 🤝 Contributing

This is a personal configuration, but feel free to take inspiration or report issues.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- NixOS community for the amazing distribution
- NUR for additional packages
- All the maintainers of the packages used in this configuration
