# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Enable the Flakes feature and the accompanying new nix command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems = {
    "/".options = [ "compress=zstd" "noatime" ];
    "/home".options = [ "compress=zstd" "noatime" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
    "/persist" = {
        options = [ "compress=zstd" "noatime" ];
        neededForBoot = true;
    };
    "/var/lib/libvirt".options = [ "compress=zstd" "noatime" ];
  };

  boot.initrd.postResumeCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-uuid/005607ab-908a-4aec-9cef-863cc6827601 /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            btrfs subvolume delete "$1"
        done
        btrfs subvolume delete "$1"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';

  # Persistence configuration
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"     # Keep NixOS configuration
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/bluetooth"
      "/var/log"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      "/var/db/sudo"  # persist sudo timestamps, so there'll be no "welcome" message
    ];
    files = [
      "/etc/machine-id"
    ];
  };


  networking.hostName = "think-nix"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Bratislava";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    pkgs-unstable.nerd-fonts.fira-code
    meslo-lgs-nf
    # (nerdfonts.override { fonts = [ "FiraCode" ]; })  # deprecated way
  ];


  fonts.fontconfig.defaultFonts.monospace = [ "MesloLGS NF" ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # services.xserver.desktopManager.plasma5.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # qt.style = "breeze";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,sk";
    variant = ",qwerty";
    options = "grp:alt_shift_toggle";  # Use Alt+Shift to switch between layouts
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true;
  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = false;

  services.usbmuxd.enable = true;

  users.mutableUsers = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.koyuch = {
    isNormalUser = true;
    # generated with `mkpasswd -m sha-512`
    hashedPassword = "$6$1ZhuIyw0X6Zsps8q$CgN2iaTNzPyA0Vf1cBDH7GtBe3euP21nPw5BnHNBjrHf.pF/weJqNgeCDGbSUBmY1U.tPcqeKK0MlDN/AkfYe/";
    extraGroups = [ "wheel" "networkmanager" "libvirtd"]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh; # Make zsh default shell

  #  packages = with pkgs; [
  #     tree
  #   ];
  };

  #programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = (with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    usbutils
    gnupg
    pinentry-qt
    git
    wget
    curl
    ncdu
    (pass.withExtensions (subpkgs: with subpkgs; [
      pass-audit
      pass-otp
      pass-genphrase
      nur.repos.onemoresuza.pass-extension-tail
    ]))
    wl-clipboard
    fira-code
    bash-completion
    nix-bash-completions
    tmux
    byobu
    kitty
    kitty-themes
    kdePackages.yakuake
    freerdp
    mpg123
    vlc
    kodi
    chromium
    krusader
    kdiff3
    virt-manager
    spotify
    wasistlos
#    teams-for-linux # not working temporarily (18.5.2025)
    slack
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
#    podman-compose # start group of containers for dev
    pre-commit
    jdk
    python3
    nodejs
    uv
    jq
    awscli2
    kubectl
    kubernetes-helm
    k9s
#    puppeteer-cli
#    xorg.libXScrnSaver
    aider-chat
    tesseract
    libimobiledevice # for iphones
    ifuse # for iphones
    android-tools      # adb & fastboot
    exfatprogs        # exfat filesystem support
#    libmtp             # MTP lib for fallback
#    jetbrains.idea-ultimate
    teams-for-linux
    qbittorrent
#    rpi-imager  # temporarily disabled - build failing with Qt6 CMake error
  ]) ++
  (with pkgs-unstable; [
    (firefox.override { nativeMessagingHosts = [ passff-host ]; })
#    aider-chat-full
    code-cursor
    windsurf
    gemini-cli
    # jetbrains.idea-ultimate
  ]);

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "spotify"
    "slack"
    "vscode-extension-github-copilot-chat"
    "idea-ultimate"
    "teams-for-linux"
  ];

  programs.zsh.enable = true;

  # Enable zsh completion. Don't forget to add
  # to your system configuration to get completion for system packages (e.g. systemd.
  environment.pathsToLink = [ "/share/zsh" ];

  services.udev.packages = [ ];

  security.pam.services.login.gnupg.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  programs.nix-ld.enable = true;

  programs.virt-manager.enable = true;
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  # Enable virtualization
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
#    podman = {
#      enable = true;
#      # Create a `docker` alias for podman, to use it as a drop-in replacement
#      dockerCompat = true;
#      dockerSocket.enable = true;
#      # Required for containers under podman-compose to be able to talk to each other.
#      defaultNetwork.settings.dns_enabled = true;
#    };
    spiceUSBRedirection.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";

      allowedBridges = ["default"];
    };
  };

  environment.sessionVariables = {
#    DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock";
    PUPPETEER_SKIP_DOWNLOAD = "true";
    PUPPETEER_EXECUTABLE_PATH = "${lib.getExe pkgs.chromium}";
  };

  # List services that you want to enable:

  security.sudo = {
    # Enable sudo
    enable = true;

    # Extend the timeout to 30 minutes (default is 5 minutes)
    extraConfig = ''
      # Set timeout to 30 minutes
      Defaults timestamp_timeout=30

      # Optional: Set per-terminal timestamps instead of global
      Defaults timestamp_type=ppid
    '';
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.autoUpgrade.enable = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}