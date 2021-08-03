{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    home.packages = [
      pkgs._1password-gui
      pkgs.spotify
      pkgs.discord
      pkgs.thunderbird
      pkgs.teams
      pkgs.slack
    ];

    programs.firefox = {
      enable = true;

      profiles.randomcat = {
        id = 0;
        isDefault = true;
        name = "randomcat";

        settings = {
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.startup.page" = 3;
        };
      };

      extensions =
        let addons = pkgs.nur.repos.rycee.firefox-addons;
        in
        [
          addons.ublock-origin
          addons.onepassword-password-manager
        ];
    };
  };
}
