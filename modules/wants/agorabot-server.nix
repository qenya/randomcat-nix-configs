{ pkgs, config, ... }:

let
  lib = pkgs.lib;
  types = lib.types;
  cfg = config.services.randomcat.agorabot-server;
  extraConfigfileModule = { name, ... }: {
    options = {
      text = lib.mkOption {
        type = types.str;
      };
    };
  };
  instancesModule = { name, ... }: {
    options = {
      package = lib.mkOption {
        type = types.package;
      };

      configSource = lib.mkOption {
        type = types.path;
      };

      dataVersion = lib.mkOption {
        type = types.int;
      };

      token = lib.mkOption {
        type = types.str;
        description = "Bot token.";
      };

      secretConfigFiles = lib.mkOption {
        type = types.attrsOf (types.submodule extraConfigfileModule);
        default = {};
      };

      extraConfigFiles = lib.mkOption {
        type = types.attrsOf (types.submodule extraConfigfileModule);
        default = {};
      };
    };
  };
in
{
  imports = [
    ./agorabot.nix
  ];

  options = {
    services.randomcat.agorabot-server = {
      enable = lib.mkEnableOption {
        name = "AgoraBot server";
      };

      user = lib.mkOption {
        type = types.str;
        description = "Name of the user for AgoraBot instances.";
      };

      root-directory = lib.mkOption {
        type = types.str;
        description = "Path of the root directory for AgoraBot instances.";
        default = "/srv/discord-bot";
      };

      instances = lib.mkOption {
        type = types.attrsOf (types.submodule instancesModule);
        default = {};
      };
    };
  };

  config =
    let
      tokenKeyNameOf = instance: "agorabot-discord-token-${instance}";
      workingDirOf = instance: "${cfg.root-directory}/${instance}";
      userGroup = config.users.users."${cfg.user}".group;
      escapeSecretConfigPath = path: (lib.replaceStrings ["/"] ["__"] path);
      secretConfigFileEntries =
        lib.concatLists
        (
          lib.mapAttrsToList
          (
            instanceName: instanceValue:
            lib.mapAttrsToList
            (
              configPath: configValue:
              {
                instance = instanceName;
                configPath = configPath;
                configText = configValue.text;
              }
            )
            instanceValue.secretConfigFiles
          )
          cfg.instances
        )
        ;
      keyNameOfConfigFileEntry = entry: "agorabot-config-${entry.instance}-${escapeSecretConfigPath entry.configPath}";
    in
    {
      users.users."${cfg.user}" = {
        isSystemUser = true;
        createHome = true;
        home = cfg.root-directory;
        extraGroups = [ "keys" ];
      };

      systemd.targets.agorabot-instances = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
      };

      deployment.keys = (lib.mapAttrs' (
        name: value:
        {
          name = tokenKeyNameOf name;
          value = {
            text = value.token;
            user = cfg.user;
            group = userGroup;
            permissions = "0640";
          };
        }
      ) cfg.instances) // (lib.listToAttrs (map (entry: {
        name = keyNameOfConfigFileEntry entry;
        value = {
          text = entry.configText;
          user = cfg.user;
          group = userGroup;
          permissions = "0640";
        };
      }) secretConfigFileEntries));

      systemd.services.agorabot-create-directories = {
        wantedBy = [ "agorabot-instances.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = userGroup;
        };

        script = lib.concatStringsSep "\n" (map (name: "mkdir -p -- ${workingDirOf name}") (lib.attrNames cfg.instances));
      };

      services.randomcat.agorabot.instances = lib.mapAttrs (
        name: value:
        (
          let 
            neededSecretConfigEntries = lib.filter (x: x.instance == name) secretConfigFileEntries;
            neededSecretConfigUnits = map (x: (keyNameOfConfigFileEntry x) + "-key.service") neededSecretConfigEntries;
          in
          {
            inherit (value) package dataVersion;
            workingDir = workingDirOf name;
            tokenFilePath = "/run/keys/${tokenKeyNameOf name}";

            configGeneratorPackage = pkgs.writeShellScriptBin "generate-config" (
            ''
              cp -RT --no-preserve=mode -- ${pkgs.lib.escapeShellArg "${value.configSource}"} "$1"
            '' +
            "\n" +
            (
              lib.concatStringsSep "\n" (map (entry: ''cp --no-preserve=mode -- ${lib.escapeShellArg "/run/keys/${keyNameOfConfigFileEntry entry}"} "$1"/${lib.escapeShellArg entry.configPath}'') neededSecretConfigEntries)
            ) +
            "\n" +
            (
              lib.concatStringsSep "\n" (lib.mapAttrsToList (configPath: configValue: ''printf "%s" ${pkgs.lib.escapeShellArg configValue.text} > "$1"/${lib.escapeShellArg configPath}'') value.extraConfigFiles)
            )
            + "\n"
            )
            ;

            unit = {
              wantedBy = [ "agorabot-instances.target" ];
              after = [ "agorabot-create-directories.service" "${tokenKeyNameOf name}-key.service" ] ++ neededSecretConfigUnits;
              wants = [ "${tokenKeyNameOf name}-key.service" ] ++ neededSecretConfigUnits;

              auth = {
                user = cfg.user;
                group = userGroup;
              };
            };

            autoRestart.enable = true;
          }
        )
      ) cfg.instances;
    };
}
