{
  config,
  pkgs,
  ...
}: {
  programs.wofi = {
    enable = true;
    settings = {
      location = "center";
      allow_markup = true;
      width = 600;
      height = 900;
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_images = true;
      image_size = 32;
      insensitive = true;
      hide_scroll = true;
      no_actions = true;
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font Mono", monospace;
        font-size: 14px;
      }

      window {
        margin: 0px;
        border: 2px solid #51afef;
        background-color: #282c34;
        border-radius: 8px;
      }

      #input {
        margin: 10px;
        padding: 10px;
        border: 2px solid #3e4451;
        background-color: #21242b;
        color: #bbc2cf;
        border-radius: 6px;
      }

      #input:focus {
        border: 2px solid #51afef;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #282c34;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #282c34;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #bbc2cf;
      }

      #entry {
        padding: 8px;
        margin: 2px;
        border-radius: 6px;
        background-color: transparent;
      }

      #entry:selected {
        background-color: #51afef;
        color: #282c34;
      }

      #entry:hover {
        background-color: #3e4451;
      }

      #entry:selected #text {
        color: #282c34;
        font-weight: bold;
      }

      #entry img {
        margin-right: 10px;
      }
    '';
  };
}
