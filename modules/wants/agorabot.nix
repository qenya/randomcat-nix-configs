{ pkgs, config,  ... }:

let
  lib = pkgs.lib;
  types = lib.types;
  cfg = config.services.randomcat.agorabot;
  instancesModule = { name, ... }: {
    options = {
      package = lib.mkOption {
        type = types.package;
      };

      configGeneratorPackage = lib.mkOption {
        type = types.package;
        description = "Package with script to generate config directory. The script should be in bin/generate-config in the output, and should accept a single argument (the directory to put the generated config in).";
      };

      dataVersion = lib.mkOption {
        type = types.int;
      };

      tokenFilePath = lib.mkOption {
        type = types.str;
        description = "Path to a file containing the bot token.";
      };

      user = lib.mkOption {
        type = types.str;
        description = "Name of the user under which to run the bot.";
        default = "agorabot";
      };

      group = lib.mkOption {
        type = types.str;
        description = "Name of the group under which to run the bot.";
        default = "agorabot";
      };

      unit = {
        wantedBy = lib.mkOption {
          type = types.listOf types.str;
          default = [ "multi-user.target" ];
        };

        after = lib.mkOption {
          type = types.listOf types.str;
          default = [ "network.target" ];
        };

        wants = lib.mkOption {
          type = types.listOf types.str;
          default = [];
        };

        description = lib.mkOption {
          type = types.str;
          default = "AgoraBot instance ${name}";
        };
      };
      
      autoRestart.enable = lib.mkEnableOption "Auto restart";
   };
  };
in
{
  options = {
    services.randomcat.agorabot = {
      instances = lib.mkOption {
        type = types.attrsOf (types.submodule instancesModule);
        default = {};
      };
    };
  };

  config =
    let
      needAgoraBotUser = lib.any (value: value.user == "agorabot") (lib.attrValues (cfg.instances));
    in
    {
      users.users = lib.optionalAttrs needAgoraBotUser {
        agorabot = {
          isSystemUser = true;
          description = "Service account for agorabot instance.";
          group = "agorabot";
          home = "/homeless-shelter";
          createHome = false;
        };
      };

      users.groups = lib.optionalAttrs needAgoraBotUser {
        agorabot = {};
      };

      systemd.services = lib.mapAttrs' (
        name: value:
        {
          name = "agorabot-instance-${name}";

          value = {
            enable = true;

            inherit (value.unit) wantedBy wants after description;

            serviceConfig = {
              User = value.user;
              Group = value.group;
              Restart = "on-failure";
              RestartSec = "30s";
              RuntimeDirectory="agorabot/${name}";
              RuntimeDirectoryMode = "700";
              StateDirectory="agorabot/${name}";
              StateDirectoryMode = "700";

              # Sandboxing
              ProtectHome = true;
              ProtectSystem = "strict";
              NoNewPrivileges = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectClock = true;
              ProtectHostname = true;
              PrivateDevices = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProtectControlGroups = true;
              SystemCallFilter = "@system-service";
              CapabilityBoundingSet = "";
              RestrictNamespaces = true;
              RestrictAddressFamilies = "AF_INET AF_INET6";
              RestrictSUIDSGID = true;
              RemoveIPC = true;
              UMask = "077";
              SystemCallArchitectures = "native";
            } // lib.optionalAttrs value.autoRestart.enable {
              Restart = "always";
            };

            script = ''
              set -euo pipefail

              BOT_CONFIG_DIR="$RUNTIME_DIRECTORY/generated-config"
              ${lib.escapeShellArg "${value.configGeneratorPackage}/bin/generate-config"} "$BOT_CONFIG_DIR"

              BOT_STORAGE_DIR="$STATE_DIRECTORY/storage"
              mkdir -p -m 700 -- "$BOT_STORAGE_DIR"

              BOT_TMP_DIR="$STATE_DIRECTORY/tmp"
              rm -rf -- "$BOT_TMP_DIR"
              mkdir -m 700 -- "$BOT_TMP_DIR"

              ${lib.escapeShellArg "${value.package}/bin/AgoraBot"} \
                --token "$(cat ${lib.escapeShellArg value.tokenFilePath})" \
                --data-version ${lib.escapeShellArg "${builtins.toString value.dataVersion}"} \
                --config-path "$BOT_CONFIG_DIR" \
                --storage-path "$BOT_STORAGE_DIR" \
                --temp-path "$BOT_TMP_DIR"
            '';
          };
        }
      ) cfg.instances;
    };
}
