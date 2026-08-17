{
  config,
  pkgs,
  ...
}: let
  panelDir = "/var/lib/pterodactyl/panel";

  wings = pkgs.stdenv.mkDerivation {
    pname = "pterodactyl-wings";
    version = "1.11.13";
    src = pkgs.fetchurl {
      url = "https://github.com/pterodactyl/wings/releases/download/v1.11.13/wings_linux_amd64";
      hash = "sha256-rKX6Rd3xwQ8JLBbddYuSDYo/qfkcN6rMYnRecpWL9xo=";
    };
    dontUnpack = true;
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    installPhase = ''
      install -Dm755 $src $out/bin/wings
    '';
  };
in {
  sops.secrets.pterodactyl-wings-config = {
    sopsFile = ../../../secrets/pterodactyl-wings.yml.enc;
    format = "binary";
    path = "/etc/pterodactyl/config.yml";
    owner = "root";
    group = "root";
    mode = "0440";
    restartUnits = ["pterodactyl-wings.service"];
  };

  users = {
    users = {
      ptero = {
        isSystemUser = true;
        group = "ptero";
        extraGroups = ["docker"];
      };
      pterodactyl-panel = {
        isSystemUser = true;
        group = "pterodactyl-panel";
        extraGroups = ["redis-pterodactyl"];
        home = panelDir;
        homeMode = "755";
        createHome = true;
      };
    };
    groups = {
      ptero = {};
      pterodactyl-panel = {};
    };
  };

  systemd = {
    services = {
      pterodactyl-wings = {
        description = "Pterodactyl Wings Daemon";
        wantedBy = ["multi-user.target"];
        after = ["docker.service" "network-online.target"];
        requires = ["docker.service"];
        wants = ["network-online.target"];
        unitConfig.ConditionPathExists = "/etc/pterodactyl/config.yml";
        path = [pkgs.shadow pkgs.bash pkgs.coreutils pkgs.gnutar pkgs.curl pkgs.gzip];
        serviceConfig = {
          Type = "simple";
          User = "root";
          ExecStart = "${wings}/bin/wings --config /etc/pterodactyl/config.yml";
          Restart = "on-failure";
          RestartSec = "5s";
          LimitNOFILE = 4096;
        };
      };
      pterodactyl-panel-queue = {
        description = "Pterodactyl Panel Queue Worker";
        wantedBy = ["multi-user.target"];
        after = ["mysql.service" "redis-pterodactyl.service"];
        requires = ["mysql.service" "redis-pterodactyl.service"];
        unitConfig.ConditionPathExists = "${panelDir}/artisan";
        path = [pkgs.mariadb pkgs.bash];
        serviceConfig = {
          Type = "simple";
          User = "pterodactyl-panel";
          Group = "pterodactyl-panel";
          WorkingDirectory = panelDir;
          ExecStart = "${pkgs.php83.withExtensions ({
            enabled,
            all,
          }:
            enabled ++ [all.redis])}/bin/php ${panelDir}/artisan queue:work --sleep=3 --tries=3 --max-time=3600";
          Restart = "always";
          RestartSec = "5s";
        };
      };
      pterodactyl-panel-schedule = {
        description = "Pterodactyl Panel Artisan Scheduler";
        unitConfig.ConditionPathExists = "${panelDir}/artisan";
        path = [pkgs.mariadb pkgs.bash];
        serviceConfig = {
          Type = "oneshot";
          User = "pterodactyl-panel";
          Group = "pterodactyl-panel";
          WorkingDirectory = panelDir;
          ExecStart = "${pkgs.php83.withExtensions ({
            enabled,
            all,
          }:
            enabled ++ [all.redis])}/bin/php ${panelDir}/artisan schedule:run";
        };
      };
    };
    timers.pterodactyl-panel-schedule = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "minutely";
        Persistent = true;
        Unit = "pterodactyl-panel-schedule.service";
      };
    };
  };

  virtualisation.docker.enable = true;

  services = {
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = ["pterodactyl"];
      ensureUsers = [
        {
          name = "pterodactyl";
          ensurePermissions."pterodactyl.*" = "ALL PRIVILEGES";
        }
      ];
    };
    redis.servers.pterodactyl = {
      enable = true;
      port = 0;
      unixSocket = "/run/redis-pterodactyl/redis.sock";
      unixSocketPerm = 660;
    };
    phpfpm.pools.pterodactyl = {
      user = "pterodactyl-panel";
      group = "pterodactyl-panel";
      phpPackage = pkgs.php83.withExtensions ({
        enabled,
        all,
      }:
        enabled ++ [all.redis]);
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 50;
        "pm.start_servers" = 10;
        "pm.min_spare_servers" = 5;
        "pm.max_spare_servers" = 20;
      };
    };
    nginx = {
      enable = true;
      virtualHosts."panel.aaronf86.tech" = {
        root = "${panelDir}/public";
        extraConfig = "index index.php;";
        locations = {
          "/" = {
            tryFiles = "$uri $uri/ /index.php?$query_string";
          };
          "~ \\.php$" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.pterodactyl.socket};
              fastcgi_index index.php;
              include ${pkgs.nginx}/conf/fastcgi_params;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              fastcgi_param HTTP_PROXY "";
            '';
          };
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [80 443 2022] ++ (builtins.genList (i: 25565 + i) 36);
    allowedUDPPorts = builtins.genList (i: 25565 + i) 36;
    interfaces.wg0.allowedTCPPorts = [8090];
  };
}
