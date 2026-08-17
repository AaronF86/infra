{
  lib,
  pkgs,
  ...
}: let
  indexHtml = pkgs.writeText "git-index.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Aaron's Git</title>
      <style>
        html { tab-size: 4; font-family: ui-sans-serif, system-ui, sans-serif; }
        body { background-color: rgb(17 24 39); color: rgb(255 255 255); margin: 0; }

        .navbar { background-color: rgb(31 41 55); box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05); padding-top: 0.5rem; padding-bottom: 0.5rem; }
        .navbar-inner { display: flex; align-items: center; gap: 1.5rem; padding-left: 1.5rem; padding-right: 1.5rem; }
        .navbar-brand { font-weight: 600; color: rgb(255 255 255); }

        .error-page { display: flex; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 1.5rem; }
        .error-card { background-color: rgb(31 41 55); border: 1px solid rgb(55 65 81); border-radius: 0.5rem; padding: 2rem; max-width: 32rem; width: 100%; }
        .error-icon { width: 4rem; height: 4rem; margin: 0 auto 1.25rem; border-radius: 9999px; background-color: rgb(30 58 138 / 0.3); display: flex; align-items: center; justify-content: center; color: rgb(96 165 250); }
        .error-title { font-size: 1.5rem; font-weight: 700; color: rgb(255 255 255); margin: 0 0 0.75rem; }
        .error-message { color: rgb(209 213 219); margin: 0 0 1.5rem; line-height: 1.6; font-size: 0.9375rem; }

        .cmd { display: inline-block; background-color: rgb(17 24 39); border: 1px solid rgb(55 65 81); border-radius: 0.375rem; padding: 0.625rem 1.25rem; font-family: ui-monospace, monospace; font-size: 0.9375rem; color: rgb(243 244 246); margin-bottom: 1.5rem; }

        .error-actions { display: flex; flex-wrap: wrap; gap: 0.75rem; justify-content: center; }
        .btn { display: inline-flex; min-height: 32px; align-items: center; gap: 0.375rem; border-radius: 0.25rem; border: 1px solid rgb(55 65 81); background-color: rgb(31 41 55); padding: 6px 0.75rem; font-size: 0.875rem; color: rgb(243 244 246); text-decoration: none; transition: background-color 150ms; }
        .btn:hover { background-color: rgb(55 65 81); }
      </style>
    </head>
    <body>
      <nav class="navbar">
        <div class="navbar-inner">
          <span class="navbar-brand">Aaron's Git</span>
        </div>
      </nav>
      <div class="error-page">
        <div class="error-card">
          <div class="error-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
            </svg>
          </div>
          <h1 class="error-title">Aaron's Git</h1>
          <p class="error-message">This is a self-hosted SSH git server.<br>Connect via SSH to browse repositories.</p>
          <div class="cmd">ssh git.aaronf86.tech -p 23231</div>
          <div class="error-actions">
            <a class="btn" href="mailto:aaron@aaronf86.tech">Contact</a>
          </div>
        </div>
      </div>
    </body>
    </html>
  '';

  webRoot = pkgs.runCommand "git-webroot" {} ''
    mkdir $out
    cp ${indexHtml} $out/index.html
  '';
in {
  users.users.soft-serve = {
    isSystemUser = true;
    group = "soft-serve";
    home = "/var/lib/soft-serve";
  };
  users.groups.soft-serve = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/soft-serve 0750 soft-serve soft-serve - -"
  ];

  services.soft-serve = {
    enable = true;
    settings = {
      name = "Aaron's Git";
      ssh = {
        listen_addr = ":23231";
        public_url = "ssh://git.aaronf86.tech:23231";
      };
      http = {
        listen_addr = ":23232";
        public_url = "https://git.aaronf86.tech";
      };
      anon_access = "read-only";
    };
  };

  systemd.services.soft-serve = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "soft-serve";
      Group = lib.mkForce "soft-serve";
      PrivateMounts = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      PrivateDevices = lib.mkForce false;
      ProtectHome = lib.mkForce false;
      ProtectControlGroups = lib.mkForce false;
      ProtectKernelTunables = lib.mkForce false;
      ProtectKernelModules = lib.mkForce false;
      ProtectKernelLogs = lib.mkForce false;
      ProtectClock = lib.mkForce false;
      ProtectHostname = lib.mkForce false;
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";
      StateDirectory = lib.mkForce "";
      WorkingDirectory = lib.mkForce "/var/lib/soft-serve";
      ExecPaths = lib.mkForce [];
    };
    environment.SOFT_SERVE_DATA_PATH = lib.mkForce "/var/lib/soft-serve";
  };

  services.nginx = {
    enable = true;
    virtualHosts."git" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 23234;
        }
      ];
      root = "${webRoot}";
    };
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [23231 23232 23234];
}
