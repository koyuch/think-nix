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
      temperature.night = 4500;
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

  # Add other home-manager configurations here

  home.stateVersion = "24.11";
}
