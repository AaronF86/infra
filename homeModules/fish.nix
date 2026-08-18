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
    functions = {
      ns = {
        body = ''nix shell (printf 'nixpkgs#%s\n' $argv)'';
        description = "nix shell nixpkgs#<pkg>";
      };
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
