{...}: {
  imports = [../../common/mdadm-monitor.nix];

  systemd = {
    services.mdadm-check = {
      description = "Check consistency of /dev/md/root";
      serviceConfig.Type = "oneshot";
      script = ''
        md=$(basename "$(readlink -f /dev/md/root)")
        echo check > "/sys/block/$md/md/sync_action"
      '';
    };

    timers.mdadm-check = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
        RandomizedDelaySec = "6h";
      };
    };
  };
}
