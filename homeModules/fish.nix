{pkgs, ...}: {
  programs.direnv = {
    enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      if command -q nix-your-shell
        nix-your-shell fish | source
      end
    '';
    shellAliases = {
      soft = "ssh -p 23231 git.aaronf86.tech";
    };
    plugins = [
      {
        name = "tide";
        inherit (pkgs.fishPlugins.tide) src;
      }
    ];
  };

  home.packages = with pkgs; [
    nix-your-shell
  ];
}
