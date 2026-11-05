{
  pkgs,
  modulesPath,
  commonArgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../common/base.nix
    ../../common/lan-dns.nix
    ../../common/smtp.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./zfs.nix
    (import ../../common/metrics.nix {})
  ];

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.241 -m multiport --dports 9100,9633 -j nixos-fw-accept
  '';

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = commonArgs.sshKeys;
  };

  networking.hostName = "grimoire";

  environment.systemPackages = with pkgs; [
    lm_sensors
    mtdutils
    i2c-tools
    minicom
  ];
}
