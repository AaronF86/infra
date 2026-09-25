{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    historyLimit = 10000;
    keyMode = "vi";
    sensibleOnTop = true;

    extraConfig = ''
      set -g mouse on

      # Pane borders
      set -g pane-border-status off

      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"

      bind R source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      bind -n C-h select-pane -L
      bind -n C-j select-pane -D
      bind -n C-k select-pane -U
      bind -n C-l select-pane -R
    '';
  };
}
