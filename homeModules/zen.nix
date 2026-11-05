{zen-browser, ...}: {
  imports = [
    zen-browser.homeModules.beta
  ];
  programs.zen-browser = {
    enable = true;
  };
  programs.zen-browser.policies = {
    AutofillAddressEnabled = true;
    AutofillCreditCardEnabled = true;
    DisableAppUpdate = true;
    DisableFeedbackCommands = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    OfferToSaveLogins = true;
    # Keep DoH, but resolve our own names through the system (LAN unbound, common/lan-dns.nix)
    # so LAN-only hosts like grafana resolve to staff
    DNSOverHTTPS = {
      Enabled = true;
      ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
      ExcludedDomains = ["aaronf86.tech"];
    };
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };
    ExtensionSettings = {
      "myallychou@gmail.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
        installation_mode = "force_installed";
      };
      "uBlock0@raymondhill.net" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      };
      "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/grammarly-1/latest.xpi";
      };
    };
  };
}
