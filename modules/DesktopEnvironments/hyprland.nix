{pkgs, ...}: {
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
  ];

  services.keyd = {
    enable = true;

    keyboards.default = {
      settings = {
        main = {
          capslock = "overload(control, esc)";
        };
      };
    };
  };
}
