{
  config,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host cafe
        HostName cafe.cis.strath.ac.uk
        User xeb24173

      Host cpunode*
        HostName %h.cis.strath.ac.uk
        User xeb24173
        ProxyCommand ssh cafe -W %h:%p
    '';
  };
}
