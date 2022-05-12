{ config, lib, pkgs, ... }:

{
  imports = [
    ./home-configs/wants/general-development.nix
    ./home-configs/wants/java-development.nix
    ./home-configs/wants/custom-gnome.nix
    ./home-configs/wants/version-control-personal.nix
    ./home-configs/wants/productivity-apps.nix
    ./home-configs/wants/custom-terminal.nix
    ./home-configs/wants/ssh.nix
    ./home-configs/wants/nixops.nix
    ./home-configs/wants/sysadmin.nix
    ./home-configs/wants/video.nix
    ./home-configs/wants/agora-backup.nix
    ./home-configs/wants/archive.nix
    ./home-configs/wants/ncsu.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.randomcat.agora-backup.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
