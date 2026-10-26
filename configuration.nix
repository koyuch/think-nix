# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable the Flakes feature and the accompanying new nix command-line tool
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # 256MB ESP shared with Windows + stale Fedora/Gentoo leftovers.
  # Each NixOS generation costs ~57MB (kernel 13MB + initrd 44-45MB),
  # so keep only 2 to avoid filling the ESP.
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems = {
    "/".options = [
      "compress=zstd"
      "noatime"
    ];
    "/home".options = [
      "compress=zstd"
      "noatime"
    ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
    "/persist" = {
      options = [
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/var/lib/libvirt".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  boot.initrd.systemd.services.btrfs-root-rotate = {
    description = "Rotate the btrfs root subvolume before it is mounted";
    wantedBy = [ "initrd.target" ];
    after = [ "initrd-root-device.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    path = with pkgs; [
      btrfs-progs
      coreutils
      findutils
      util-linux
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-uuid/005607ab-908a-4aec-9cef-863cc6827601 /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30 | while read -r old_root; do
        if [[ -d "$old_root" ]]; then
           echo "Deleting old root: $old_root"
           # Delete nested subvolumes first
           btrfs subvolume list -o "$old_root" | cut -f 9- -d ' ' | sort -r | while read -r subvol; do
               btrfs subvolume delete "/btrfs_tmp/$subvol"
           done
           btrfs subvolume delete "$old_root"
        fi
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };

  # Persistence configuration
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos" # Keep NixOS configuration
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/tailscale"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/coredump"
      "/var/lib/bluetooth"
      "/var/log"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
      "/var/db/sudo" # persist sudo timestamps, so there'll be no "welcome" message
      "/var/lib/fprint" # fprintd enrolled fingerprints
    ];
    files = [
      "/etc/machine-id"
      # Required by libvirtd's LoadCredentialEncrypted=secrets-encryption-key.
      # /var/lib/systemd/credential.secret is the host key that decrypts
      # /var/lib/libvirt/secrets/secrets-encryption-key (which lives on the
      # persistent var/lib/libvirt subvolume). Without persisting the host key,
      # every reboot wipes it (root subvolume is rotated), the
      # virt-secret-init-encryption.service is skipped (ConditionPathExists),
      # and libvirtd fails with 243/CREDENTIALS.
      "/var/lib/systemd/credential.secret"
    ];
  };

  networking.hostName = "think-nix"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

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
    options = "grp:alt_shift_toggle"; # Use Alt+Shift to switch between layouts
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true;

  # Synaptics Prometheus 06cb:00bd fingerprint reader (libfprint synaptics driver, no TOD needed)
  services.fprintd.enable = true;
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
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "podman"
    ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh; # Make zsh default shell

    #  packages = with pkgs; [
    #     tree
    #   ];
  };

  #programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # NOTE: Nix has no "meta package" for a base CLI set - the groups below
  # are plain comments inside one list. If this grows, move groups into
  # `let baseCli = with pkgs; [ ... ]; in` bindings.
  environment.systemPackages =
    (with pkgs; [
      # --- Shell / terminal basics ---
      # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      bash-completion
      nix-bash-completions
      gnumake
      tmux
      byobu
      kitty
      kitty-themes
      kdePackages.yakuake
      wl-clipboard
      fira-code
      vim
      less

      # --- Modern CLI replacements (base set) ---
      ripgrep # rg - grep alternative
      fd # find alternative
      fzf # fuzzy finder
      bat # cat alternative
      zoxide # z - smart cd
      eza # ls alternative
      btop # htop alternative
      ncdu # ncdu - disk usage
      dust # du alternative
      duf # df alternative
      procs # ps alternative
      tldr # concise man pages
      tree # directory tree
      jq # json query tool
      yq # yaml query tool

      # --- Files / archives / sync ---
      file
      zip
      unzip
      p7zip # 7z, incl. rar extraction
      rsync

      # --- Network / DNS / HTTP ---
      # mtr provided via programs.mtr
      dog # modern dig alternative
      nmap
      iperf3
      socat
      xh # friendly httpie-like client
      httpie

      # --- Monitoring / hardware / tracing ---
      # usbutils (lsusb) below in mobile section too
      lsof
      strace
      pciutils # lspci
      lm_sensors # sensors
      iotop

      # --- Nix / dev helpers ---
      gh # github CLI
      just # command runner
      nil # nix LSP
      alejandra # nix formatter
      nix-tree # inspect /nix/store
      pre-commit
      jdk
      python3
      nodejs
      uv

      # --- Security / secrets ---
      usbutils
      gnupg
      pinentry-qt
      git
      wget
      curl
      (pass.withExtensions (
        subpkgs: with subpkgs; [
          pass-audit
          pass-otp
          pass-genphrase
          nur.repos.onemoresuza.pass-extension-tail
        ]
      ))

      # --- Remote / desktop ---
      freerdp
      mpg123
      vlc
      kodi
      chromium
      krusader
      kdiff3
      virt-manager
      spotify
      # wasistlos
      # teams-for-linux # not working temporarily (18.5.2025)
      slack
      dive # look into docker image layers
      podman-tui # status of containers in the terminal
      # docker-compose # start group of containers for dev
      podman-compose # start group of containers for dev
      awscli2
      kubectl
      kubernetes-helm
      k9s
      #    puppeteer-cli
      #    xorg.libXScrnSaver
      tesseract
      libimobiledevice # for iphones
      ifuse # for iphones
      android-tools # adb & fastboot
      exfatprogs # exfat filesystem support
      #    libmtp             # MTP lib for fallback
      #    jetbrains.idea-ultimate
      teams-for-linux
      qbittorrent
      rpi-imager # temporarily disabled - build failing with Qt6 CMake error
    ])
    ++ (with pkgs-unstable; [
      (firefox.override { nativeMessagingHosts = [ passff-host ]; })
      # aider-chat-full
      # aider-chat # disabled 2026-10-26: unstable pulls broken python3.14-posthog-7.71.0 (mcp>=2); re-enable after upstream fix
      # code-cursor
      # windsurf
      codex
      codex-acp
      codex-relay
      codex-security
      antigravity-cli
      antigravity-ide
      opencode
      # jetbrains.idea-ultimate
    ]);

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "slack"
      # "vscode-extension-github-copilot-chat"
      # "idea-ultimate"
      "teams-for-linux"
    ];

  programs.zsh.enable = true;

  # Enable zsh completion. Don't forget to add
  # to your system configuration to get completion for system packages (e.g. systemd.
  environment.pathsToLink = [ "/share/zsh" ];

  services.udev.packages = [ ];

  security.pam.services.login.gnupg.enable = true;

  # Fingerprint only for sudo (agents' sudo calls = one finger touch; password stays
  # as fallback). NixOS defaults fprintAuth to fprintd.enable for every PAM service;
  # keep password-only for login/sddm so pam_gnupg gets the password to unlock
  # gpg-agent. Plasma's screen locker runs the separate kde-fingerprint service in
  # parallel with password, so "kde" stays password-only.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.sddm.fprintAuth = false;
  security.pam.services.kde.fprintAuth = false;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  programs.nix-ld.enable = true;

  programs.virt-manager.enable = true;
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  # Enable virtualization
  virtualisation = {
    # docker = {
    #   enable = true;
    #   storageDriver = "btrfs";
    #   rootless = {
    #     enable = true;
    #     setSocketVariable = true;
    #   };
    # };
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      dockerSocket.enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";

      allowedBridges = [ "default" ];
    };
  };

  environment.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock";
    PUPPETEER_SKIP_DOWNLOAD = "true";
    PUPPETEER_EXECUTABLE_PATH = "${lib.getExe pkgs.chromium}";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    openFirewall = true;
  };

  # Tailscale MagicDNS overwrites /etc/resolv.conf when NM uses the resolvconf
  # backend. After suspend/resume WiFi (iwlwifi) takes ~10s to re-DHCP, and
  # tailscaled re-reads an empty upstream list (Resolvercfg .:[] -> SERVFAIL
  # until manual `tailscale down/up`). systemd-resolved gives Tailscale a
  # stable DBus API for upstream DNS, surviving resume.
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  # Best practice for a roaming laptop (also Tailscale-compatible):
  # - DNSSEC=allow-downgrade: validate when the upstream supports it, fall
  #   back on captive portals / home routers (10.0.0.1) that don't. `true`
  #   would hard-fail on those networks.
  # - DNSOverTLS=opportunistic: encrypt to providers that support it
  #   (fallback Quad9/Cloudflare), plaintext fallback for local routers
  #   without TLS. `strict` would break 10.0.0.1.
  # - LLMNR=false: legacy spoof-prone protocol; mDNS stays on for .local
  #   (printers, Chromecast). Tailscale already disables both on tailscale0.
  # Cache stays at its default (yes) for efficiency.
  services.resolved.settings.Resolve = {
    DNSSEC = "allow-downgrade";
    DNSOverTLS = "opportunistic";
    LLMNR = false;
    MulticastDNS = true;
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose";
  };

  # List services that you want to enable:

  security.sudo = {
    # Enable sudo
    enable = true;

    extraConfig = ''
      # Short timeout (15s = 0.25m) so chained sudo commands in a single shell
      # call share one fingerprint touch, while separate calls prompt again.
      Defaults timestamp_timeout=0.25

      # Global per-user timestamp (default was tty, and ppid broke wrapper scripts
      # like asudo where sudo -v and exec sudo had different parent PIDs).
      Defaults timestamp_type=global
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Host keys live on the root subvolume by default, which is wiped on every
  # boot (impermanence). Keep them under /persist so the host identity (and
  # clients' known_hosts) survives reboots. Seed once before the next reboot:
  #   sudo mkdir -p /persist/etc/ssh && sudo cp -a /etc/ssh/ssh_host_* /persist/etc/ssh/
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/persist/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ]; # SSH
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
