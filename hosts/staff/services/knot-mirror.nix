{
  config,
  pkgs,
  ...
}: let
  mirrorScript = pkgs.writeShellApplication {
    name = "knot-mirror";
    runtimeInputs = with pkgs; [git curl openssh jq coreutils];
    text = ''
      GITHUB_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
      GITHUB_USER="aaronf86"
      OWNER_DID="did:plc:e2nksyu6bnw6lczckjhqweau"
      KNOT_HOST="knot.aaronf86.tech"
      SS_HOST="git.aaronf86.tech"
      SS_PORT="23231"
      SS_KEY="/var/lib/knot-mirror/.ssh/soft-serve"
      MIRROR_DIR="/var/lib/knot-mirror"

      ss_ssh() {
        ssh -n -i "$SS_KEY" -p "$SS_PORT" \
          -o StrictHostKeyChecking=accept-new \
          -o UserKnownHostsFile="$MIRROR_DIR/.ssh/known_hosts" \
          -o ConnectTimeout=10 \
          -o ServerAliveInterval=10 \
          -o ServerAliveCountMax=3 \
          "$SS_HOST" "$@"
      }

      echo "Starting knot mirror run"
      failed=0

      # Repo list comes from the owner's PDS and clones go over the knot's
      # public HTTPS endpoint, so nothing here needs the knot's local files.
      pds=$(curl -sf "https://plc.directory/$OWNER_DID" \
        | jq -r '.service[] | select(.type == "AtprotoPersonalDataServer") | .serviceEndpoint')
      repos=$(curl -sf "$pds/xrpc/com.atproto.repo.listRecords?repo=$OWNER_DID&collection=sh.tangled.repo&limit=100" \
        | jq -r '.records[] | [(.uri | split("/") | last), (.value.name // "")] | @tsv')
      echo "Found $(printf '%s\n' "$repos" | grep -c .) repos for $OWNER_DID"

      while IFS=$'\t' read -r repo rname; do
        [[ -n "$repo" ]] || continue
        # Records keyed by a TID carry the real repo name in the record.
        if [[ "$repo" =~ ^3[a-z2-7]{12}$ && -n "$rname" ]]; then
          repo="$rname"
        fi
        echo "[$repo] Processing"

        mirror_dir="$MIRROR_DIR/$repo.git"
        knot_url="https://$KNOT_HOST/$OWNER_DID/$repo"
        if [[ -d "$mirror_dir" ]]; then
          echo "[$repo] Updating existing mirror at $mirror_dir"
          git -C "$mirror_dir" remote set-url origin "$knot_url"
          git -C "$mirror_dir" remote update --prune || {
            echo "[$repo] FAILED: could not update from $knot_url"
            failed=$((failed + 1))
            continue
          }
        else
          # A record on the PDS can outlive (or precede) the repo on the knot;
          # skip those instead of failing the whole run every time.
          if ! git ls-remote "$knot_url" > /dev/null 2>&1; then
            echo "[$repo] Warning: not found on knot at $knot_url, skipping"
            continue
          fi
          echo "[$repo] Cloning new mirror from $knot_url"
          git clone --mirror "$knot_url" "$mirror_dir" || {
            echo "[$repo] FAILED: could not clone $knot_url"
            rm -rf "$mirror_dir"
            failed=$((failed + 1))
            continue
          }
        fi

        echo "[$repo] Checking GitHub repo existence"
        if ! curl -sf \
          -H "Authorization: Bearer $GITHUB_TOKEN" \
          -H "Accept: application/vnd.github+json" \
          "https://api.github.com/repos/$GITHUB_USER/$repo" > /dev/null; then
          echo "[$repo] GitHub repo not found, creating"
          curl -sf -X POST \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "https://api.github.com/user/repos"
          echo "[$repo] Created GitHub repo"
          sleep 2
        else
          echo "[$repo] GitHub repo already exists"
        fi


        echo "[$repo] Pushing to GitHub"
        git -C "$mirror_dir" push --mirror \
          "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$repo.git" || {
          echo "[$repo] FAILED: push to GitHub"
          failed=$((failed + 1))
          continue
        }
        echo "[$repo] Pushed to GitHub"

        echo "[$repo] Checking Soft Serve"
        if ! ss_ssh repo info "$repo" > /dev/null 2>&1; then
          echo "[$repo] Not found in Soft Serve, importing"
          import_rc=0
          import_out=$(timeout 60 ssh -n -i "$SS_KEY" -p "$SS_PORT" \
            -o StrictHostKeyChecking=accept-new \
            -o UserKnownHostsFile="$MIRROR_DIR/.ssh/known_hosts" \
            -o ConnectTimeout=10 \
            -o ServerAliveInterval=10 \
            -o ServerAliveCountMax=3 \
            "$SS_HOST" repo import "$repo" "https://$KNOT_HOST/$OWNER_DID/$repo" 2>&1) || import_rc=$?
          if [[ "$import_rc" -eq 0 ]]; then
            echo "[$repo] Imported to Soft Serve"
          elif [[ "$import_out" == *"already exists"* ]]; then
            echo "[$repo] Already present in Soft Serve (repo info could not see it)"
          else
            echo "[$repo] Warning: Soft Serve import failed or timed out: $import_out"
          fi
        else
          echo "[$repo] Already present in Soft Serve"
        fi

        echo "[$repo] Mirroring complete"
      done <<< "$repos"

      echo "Knot mirror run finished ($failed failed)"
      [[ "$failed" -eq 0 ]]
    '';
  };
in {
  sops.secrets.github-pat = {
    sopsFile = ../../../secrets/github-pat.txt.enc;
    format = "binary";
    owner = "git-mirror";
    group = "git-mirror";
    mode = "0400";
  };

  users.users.git-mirror = {
    isSystemUser = true;
    group = "git-mirror";
    extraGroups = ["git"];
    home = "/var/lib/knot-mirror";
    createHome = false;
  };

  users.groups.git-mirror = {};

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/knot-mirror 0750 git-mirror git-mirror -"
      "d /var/lib/knot-mirror/.ssh 0700 git-mirror git-mirror -"
      "z /var/lib/knot-mirror/.ssh 0700 git-mirror git-mirror -"
    ];
    services.knot-mirror = {
      description = "Mirror Tangled knot repos to Soft Serve and GitHub";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        User = "git-mirror";
        Group = "git-mirror";
        ExecStart = "${mirrorScript}/bin/knot-mirror";
        TimeoutSec = 300;
      };
    };
    timers.knot-mirror = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "5m";
        RandomizedDelaySec = "30s";
      };
    };
  };
}
