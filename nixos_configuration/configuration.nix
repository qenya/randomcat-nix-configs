# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  selfLinkSpecPath = ./self-link.nix;
  canSelfLink = builtins.pathExists selfLinkSpecPath;
in

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./device-dir
  ];

  environment.etc."nixos" = pkgs.lib.mkIf canSelfLink {
    source = (import selfLinkSpecPath).etc_nixos_dir;
  };
}

