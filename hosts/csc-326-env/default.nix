{ config, pkgs, lib, ... }:

{
  imports = [
    ../../presets/ncsu-vm-env.nix
    ./locale.nix
    ./development.nix
    ./eclipse.nix
    ./mysql.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?

    virtualisation.writableStore = true;
    virtualisation.writableStoreUseTmpfs = false;

    virtualisation.sharedDirectories.hostshare = {
      source = "/home/randomcat/dev/csc-326-env/shared-dir";
      target = "/host-shared";
    };

    environment.systemPackages = [
      pkgs.libreoffice
      pkgs.steam-run
    ];
  };
}
