{pkgs, ...}: {
  home.packages = with pkgs; [
    ghostty
  ];

  home.sessionVariables = {
    TERMINAL = "ghostty";
  };
}
