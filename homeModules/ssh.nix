_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = false;
      AddKeysToAgent = "no";
      Compression = false;
      ServerAliveInterval = 0;
      ServerAliveCountMax = 3;
      HashKnownHosts = false;
      UserKnownHostsFile = "~/.ssh/known_hosts";
      ControlMaster = "no";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "no";
    };
    extraConfig = ''
      Host cafe
        HostName cafe.cis.strath.ac.uk
        User xeb24173

      Host cpunode*
        HostName %h.cis.strath.ac.uk
        User xeb24173
        ProxyCommand ssh cafe -W %h:%p

      Host gateway
        HostName 10.44.0.1
        Port 2222
        User aaron

      Host framework13
        HostName 10.44.0.5
        Port 2222
        User aaron
    '';
  };
}
