
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Enable the Flakes feature and the accompanying new nix command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
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
    "/var/log".options = [ "compress=zstd" "noatime" ];
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
      "/var/lib/libvirt"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
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
    noto-fonts-emoji
    fira-code
    fira-code-symbols
  ];


  fonts.fontconfig.defaultFonts.monospace = [ "Fira Code" ];

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
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = false;

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
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    gnupg
    pinentry
    git
    wget
    curl
    ncdu
    (pass.withExtensions (subpkgs: with subpkgs; [
      pass-audit
      pass-otp
      pass-genphrase
    ]))
    fira-code
    zsh-completions
    nix-zsh-completions
    bash-completion
    nix-bash-completions
    kitty
    kitty-themes
    mpg123
    vlc
    firefox
    chromium
    krusader
    kdiff3
    zsh-powerlevel10k
    vscodium
    virt-manager-qt
    jetbrains.idea-ultimate
    spotify
    whatsapp-for-linux
    teams-for-linux
    slack
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    #docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
             "idea-ultimate"
             "spotify"
             "slack"
           ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.git = {
    enable = true;
    config = {
      user.name = "Michal Koyuch";
      user.email = "michal@koyuch.dev";
      init.defaultBranch = "main";
    };
  };

  # enable zsh and oh my zsh
  programs = {
    zsh = {
      enable = true;
      enableBashCompletion = true;
      autosuggestions.enable = true;
      zsh-autoenv.enable = true;
      syntaxHighlighting.enable = true;
      promptInit = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '';
      ohMyZsh = {
         enable = true;
         plugins = [
           "git"
           "history"
           "aliases"
           "colored-man-pages"
           "colorize"
           "command-not-found"
           "python"
           "rust"
           "docker"
           "man"
           "sudo"
           "pass"
           "systemd"
           "history-substring-search"
         ];
      };
    };
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  # Enable virtualization
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd.enable = true;
  };

  # List services that you want to enable:

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

