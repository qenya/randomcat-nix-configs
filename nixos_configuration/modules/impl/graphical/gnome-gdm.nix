{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
   # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = false;
    services.xserver.desktopManager.gnome.enable = true;
  };
}
