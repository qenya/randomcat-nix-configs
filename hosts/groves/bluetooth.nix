{ config, pkgs, ... }:

{
  config = {
    hardware.bluetooth.enable = true;

    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
}
