{smart ? true}: _: {
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = ["systemd"];
    };
    smartctl.enable = smart;
  };
}
