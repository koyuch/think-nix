# home.nix
{ config, pkgs, ... }:

{
  programs.konsole.profiles."Default" = {
#    font.name = "MesloLGS NF";
    extraConfig = {
      HistorySize = 10000;
    };
  };

  programs.plasma = {
    enable = true;

    fonts = {
      fixedWidth = {
        family = "MesloLGS NF";
        pointSize = 11;
      };
    };

    workspace.wallpaperPictureOfTheDay.provider = "bing";
    kscreenlocker.appearance.wallpaperPictureOfTheDay.provider = "bing";

    workspace = {
#      colorScheme = "BreezeDark";
      lookAndFeel = "org.kde.breezedark.desktop";
#      theme = "breeze-dark";
    };

    kwin.nightLight = {
      enable = true;
      location = {
        latitude = "49.4";
        longitude = "18.625";
      };
      mode = "location";
      temperature.night = 2700;
      transitionTime = 120;
    };


    powerdevil = {
      AC = {
#        powerButtonAction = "lockScreen";
        autoSuspend = {
#          action = "nothing";
          idleTimeout = 1800;
        };
#        turnOffDisplay = {
#          idleTimeout = 1000;
#          idleTimeoutWhenLocked = "immediately";
#        };
      };
      battery = {
        powerButtonAction = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
      };
      lowBattery = {
        whenLaptopLidClosed = "hibernate";
      };
    };
  };

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true;
  };

  services.pass-secret-service.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  programs.git = {
    enable = true;
    userName = "Michal Koyuch";
    userEmail = "michal@koyuch.dev";
    signing = {
      key = "0558120E76D07CBE";
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core.autocrlf = "input";
      push.autoSetupRemote = true;
    };
  };

  home.packages = with pkgs; [
    zsh-completions
    nix-zsh-completions
    zsh-powerlevel10k
    # Other user-specific packages
  ];

  # enable zsh and oh my zsh
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
    oh-my-zsh = {
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
        "podman"
        "man"
        "sudo"
        "pass"
        "systemd"
        "history-substring-search"
      ];
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Add other home-manager configurations here

  home.stateVersion = "24.11";
}
