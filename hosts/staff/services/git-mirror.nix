{
  config,
  pkgs,
  ...
}: let
  mirrorScript = pkgs.writeShellScript "git-mirror" ''
    #!/bin/bash
    GIT=${pkgs.git}/bin/git
    CURL=${pkgs.curl}/bin/curl
    JQ=${pkgs.jq}/bin/jq
    SSH=${pkgs.openssh}/bin/ssh

    GITLAB_TOKEN=$(cat ${config.sops.secrets.gitlab-mirror-token.path})
    SS_TOKEN=$(cat ${config.sops.secrets.soft-serve-mirror-token.path})
    SS_SSH_KEY="/var/lib/soft-serve/ssh/soft_serve_host_ed25519"
    SS_URL="https://aaronf86:$SS_TOKEN@git.aaronf86.tech"
    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT

    export GIT_SSH_COMMAND="$SSH -i $SS_SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    ss_ssh() {
      $SSH -n -i "$SS_SSH_KEY" -p 23231 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        git.aaronf86.tech "$@"
    }

    SS_REPOS=$(ss_ssh repo list 2>/dev/null || true)

    ensure_repo() {
      local name="$1" private="$2"
      if ! echo "$SS_REPOS" | grep -qx "$name"; then
        if [ "$private" = "true" ]; then
          ss_ssh repo create "$name" -p 2>&1 || true
        else
          ss_ssh repo create "$name" 2>&1 || true
        fi
        SS_REPOS=$(printf '%s\n%s' "$SS_REPOS" "$name")
      fi
    }

    mirror_repo() {
      local name="$1" clone_url="$2" private="$3"
      echo "=== Mirroring $name ==="
      ensure_repo "$name" "$private"
      local clone_dir="$WORKDIR/$name.git"
      if $GIT clone --mirror "$clone_url" "$clone_dir" 2>&1; then
        if ! $GIT -C "$clone_dir" push --mirror "$SS_URL/$name" 2>&1; then
          echo "[WARN] Push failed for $name"
        fi
        rm -rf "$clone_dir"
      else
        echo "[WARN] Clone failed for $name"
        rm -rf "$clone_dir"
      fi
    }

    echo "--- GitLab Strathclyde ---"
    page=1
    while true; do
      response=$($CURL -sf \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "https://gitlab.cis.strath.ac.uk/api/v4/projects?membership=true&owned=true&per_page=100&page=$page")
      count=$(echo "$response" | $JQ length)
      echo "Page $page: $count repos found"
      [ "$count" -eq 0 ] && break
      while IFS=$'\t' read -r name ssh_url visibility; do
        echo "Processing: $name ($visibility)"
        if [ "$visibility" != "public" ]; then private="true"; else private="false"; fi
        mirror_repo "strath-$name" "$ssh_url" "$private"
      done < <(echo "$response" | $JQ -r '.[] | [.path, .ssh_url_to_repo, .visibility] | @tsv')
      page=$((page + 1))
    done

    echo "--- Done ---"
  '';
in {
  sops.secrets.gitlab-mirror-token = {
    sopsFile = ../../../secrets/gitlab-mirror-token.enc;
    format = "binary";
    owner = "soft-serve";
    mode = "0400";
  };

  sops.secrets.soft-serve-mirror-token = {
    sopsFile = ../../../secrets/soft-serve-mirror-token.enc;
    format = "binary";
    owner = "soft-serve";
    mode = "0400";
  };

  systemd.services.git-mirror = {
    description = "Mirror GitLab Strathclyde repos to Soft Serve";
    serviceConfig = {
      Type = "oneshot";
      User = "soft-serve";
      Group = "soft-serve";
      ExecStart = "${mirrorScript}";
      WorkingDirectory = "/var/lib/soft-serve";
    };
  };

  systemd.timers.git-mirror = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
