{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    ghostty
  ];

  home.sessionVariables = {
    TERMINAL = "ghostty";
  };
}
