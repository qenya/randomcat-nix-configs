{ config, lib, pkgs, ... }:

{
  config = {
    programs.git = {
      userEmail = "jason.e.cobb@gmail.com";
      userName = "Janet Cobb";
    };
  };
}
