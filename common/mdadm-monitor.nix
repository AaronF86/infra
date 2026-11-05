{pkgs, ...}: let
  mdadmEvent = pkgs.writeShellScript "mdadm-event" ''
    ${pkgs.util-linux}/bin/logger -t mdadm -p daemon.warning "$1 on $2 $3"
  '';
in {
  boot.swraid.mdadmConf = ''
    PROGRAM ${mdadmEvent}
    MAILADDR root
  '';
}
