# home.nix
{ config, pkgs, pkgs-unstable, ... }:

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
        dimDisplay = {
#          enable = false;
          idleTimeout = 900;
        };
        turnOffDisplay = {
          idleTimeout = 900;
#          idleTimeoutWhenLocked = "immediately";
        };
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
    defaultCacheTtl = 28800;        # 8 hours
    maxCacheTtl = 86400;            # 24 hours
    defaultCacheTtlSsh = 28800;     # 8 hours for SSH keys
    maxCacheTtlSsh = 86400;         # 24 hours for SSH keys
    extraConfig = ''
      pinentry-program ${pkgs.pinentry-qt}/bin/pinentry
    '';
    sshKeys = [
      "~/.ssh/id_ed25519"
      "~/.ssh/koyuch@trivia.pem"
    ];
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

  programs.bash = {
    enable = true;
  };

  # enable zsh and oh my zsh
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
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
        "helm"
      ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.vscode = with pkgs-unstable; {
        enable = true;
        package = vscodium; # or pkgs.vscode
        profiles.default.extensions =
          (with vscode-extensions; [
            github.copilot
            github.copilot-chat
            visualstudioexptteam.vscodeintellicode
          ]) ++
  #        vscode-utils.extensionsFromVscodeMarketplace [
  #          {
  #            name = "copilot-chat";
  #            publisher = "github";
  #            version = "0.26.2025030506"; # Replace with your desired version
  #            sha256 = "sha256-mCmZs5xGxcqHyo8NyMjk2mu9LmxFlMb2NGUwjXg27JA="; # Replace with actual hash
  #          }
  #          {
  #            # https://marketplace.visualstudio.com/items?itemName=Codeium.codeium
  #            name = "codeium";
  #            publisher = "Codeium";
  #            version = "1.42";
  #            sha256 = "WejMBIG7bl7iOPsdB22jqNmT7hfCsJ/1j4P/Clv/t74=";
  #          }
  #        ] ++
          (with vscode-marketplace; [
            tomaszbartoszewski.avro-tools
          ]) ++
  #        (with (forVSCodeVersion vscodium.version).vscode-marketplace ; [
  #          github.copilot-chat
  #        ]) ++
          (with open-vsx; [
            jnoortheen.nix-ide
#            continue.continue
            saoudrizwan.claude-dev
            rooveterinaryinc.roo-cline
            kilocode.kilo-code
            codeium.codeium # windsurf
            vscjava.vscode-java-pack
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-maven
            vscjava.vscode-gradle
            vscjava.vscode-java-dependency
            ms-azuretools.vscode-docker
            ms-kubernetes-tools.vscode-kubernetes-tools
            redhat.vscode-yaml
            sonarsource.sonarlint-vscode
            jeppeandersen.vscode-kafka
            bierner.markdown-mermaid
  #          amazonwebservices.amazon-q-vscode
          ]);
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Add other home-manager configurations here

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11";
}