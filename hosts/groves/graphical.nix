{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/graphical/gnome-gdm.nix
    ../../modules/impl/graphical/io/sound.nix
    ../../modules/impl/graphical/io/touchpad.nix
  ];

  config = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.opengl.enable = true;

    hardware.nvidia.prime = {
      offload.enable = true;

      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };

    environment.systemPackages =
      let
        nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
          exec -a "$0" "$@"
        '';
      in
      [ nvidia-offload];
  };
}
