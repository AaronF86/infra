{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Aaron Fulton";
        email = "dev@aaronf86.tech";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };

    ignores = [
      "*~"
      "*.swp"
      "*.swo"
      ".DS_Store"
      ".idea/"
      "*.iml"
      ".vscode/"
      "node_modules/"
      "__pycache__/"
      "*.pyc"
      ".env"
      ".direnv/"
      ".sops.yaml"
    ];
  };

  home.file = {
    ".config/git/github.conf".text = ''
      [user]
        name = Aaron Fulton
        email = dev@aaronf86.tech
    '';
    ".config/git/gitlab.conf".text = ''
      [user]
        name = Aaron Fulton
        email = dev@aaronf86.tech
    '';
    ".config/git/gitlab-strath.conf".text = ''
      [user]
        name = Aaron Fulton
        email = aaron.fulton.2024@uni.strath.ac.uk
    '';
  };
}
