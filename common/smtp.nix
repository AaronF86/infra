{config, ...}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets.smtp-password = {
    sopsFile = ../secrets/smtp-password.txt.enc;
    format = "binary";
    mode = "0400";
  };

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults.aliases = "/etc/aliases";
    accounts.default = {
      host = "smtp.protonmail.ch";
      port = 587;
      tls = true;
      tls_starttls = true;
      auth = true;
      user = "no-reply@aaronf86.tech";
      from = "no-reply@aaronf86.tech";
      passwordeval = "cat ${config.sops.secrets.smtp-password.path}";
    };
  };

  environment.etc.aliases.text = ''
    root: aaron@aaronf86.tech
    default: aaron@aaronf86.tech
  '';
}
