{
  config,
  pkgs,
  ...
}: let
  mirrorScript = pkgs.writeShellApplication {
    name = "knot-mirror";
    runtimeInputs = with pkgs; [git curl openssh sqlite];
    text = ''
      GITHUB_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
      SSH_KEY="${config.sops.secrets.git-mirror-ssh-key.path}"
      GITHUB_USER="aaronf86"
      OWNER_DID="did:plc:e2nksyu6bnw6lczckjhqweau"
      KNOT_DB="/var/lib/knot/knot.db"
      KNOT_GIT="/var/lib/knot/git"
      KNOT_HOST="knot.aaronf86.tech"
      KNOT_NAMESPACE="aaronf86.tech"
      SS_HOST="git.aaronf86.tech"
      SS_PORT="23231"
      MIRROR_DIR="/var/lib/knot-mirror"

      ss_ssh() {
        ssh -n -i "$SSH_KEY" -p "$SS_PORT" \
          -o StrictHostKeyChecking=accept-new \
          -o UserKnownHostsFile="$MIRROR_DIR/.ssh/known_hosts" \
          "$SS_HOST" "$@"
      }

      sqlite3 "$KNOT_DB" \
        "SELECT rkey, repo_did FROM repo_aliases WHERE owner_did = '$OWNER_DID';" \
      | while IFS='|' read -r repo repo_did; do
        repo_path="$KNOT_GIT/$repo_did"
        [[ -d "$repo_path" ]] || { echo "Skipping $repo: storage path missing"; continue; }

        if ! curl -sf \
          -H "Authorization: Bearer $GITHUB_TOKEN" \
          -H "Accept: application/vnd.github+json" \
          "https://api.github.com/repos/$GITHUB_USER/$repo" > /dev/null; then
          curl -sf -X POST \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "https://api.github.com/user/repos"
          echo "Created GitHub repo: $repo"
          sleep 2
        fi

        mirror_dir="$MIRROR_DIR/$repo.git"
        if [[ -d "$mirror_dir" ]]; then
          git -C "$mirror_dir" remote update --prune
        else
          git clone --mirror "$repo_path" "$mirror_dir"
        fi
        git -C "$mirror_dir" push --mirror \
          "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$repo.git"

        # Import to Soft Serve if not already present (SS handles subsequent syncs via cron)
        if ! ss_ssh repo info "$repo" > /dev/null 2>&1; then
          if ss_ssh repo import "$repo" "git@$KNOT_HOST:$KNOT_NAMESPACE/$repo"; then
            echo "Imported $repo to Soft Serve"
          else
            echo "Warning: Soft Serve import failed for $repo"
          fi
        fi

        echo "Mirrored: $repo"
      done
    '';
  };
in {
  sops.secrets.github-pat = {
    sopsFile = ../../../secrets/github-pat.txt.enc;
    format = "binary";
    owner = "git";
    group = "git";
    mode = "0400";
  };

  sops.secrets.git-mirror-ssh-key = {
    sopsFile = ../../../secrets/git-mirror-ssh-key.pem.enc;
    format = "binary";
    owner = "git";
    group = "git";
    mode = "0400";
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/knot-mirror 0750 git git -"
      "d /var/lib/knot-mirror/.ssh 0700 git git -"
    ];
    services.knot-mirror = {
      description = "Mirror Tangled knot repos to Soft Serve and GitHub";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        User = "git";
        Group = "git";
        ExecStart = "${mirrorScript}/bin/knot-mirror";
      };
    };
    timers.knot-mirror = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
        RandomizedDelaySec = "30s";
      };
    };
  };
}
