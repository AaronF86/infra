_: {
  services.samba = {
    enable = true;
    openFirewall = true;
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        security = "user";
        "map to guest" = "Bad User";
        "server min protocol" = "SMB2";
      };

      storage = {
        path = "/mnt/storage/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "root";
        "force group" = "root";
        "create mask" = "0777";
        "directory mask" = "0777";
        comment = "Grimoire NVMe storage";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  services.avahi.extraServiceFiles.smb = ''
    <?xml version="1.0" standalone='no'?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name replace-wildcards="yes">%h</name>
      <service>
        <type>_smb._tcp</type>
        <port>445</port>
      </service>
      <service>
        <type>_device-info._tcp</type>
        <port>0</port>
        <txt-record>model=Xserve</txt-record>
      </service>
    </service-group>
  '';

  systemd = {
    tmpfiles.rules = [
      "d /mnt/storage/share 0777 root root -"
    ];

    services.samba-smbd.unitConfig.RequiresMountsFor = ["/mnt/storage/share"];
  };
}
