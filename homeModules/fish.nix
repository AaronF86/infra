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
