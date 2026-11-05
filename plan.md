# Migration day — 2026-10-28

**Goal:** staff on 2 × 2 TB RAID1, grimoire on 4 × 4 TB ZFS RAIDZ1, Stalwart gone, LAN DNS, admin SSH behind WireGuard,
Nextcloud + Authentik live.

**Order is chosen for least downtime:** staff first (that's all the public services — PDS, Knot, git, Spindle),
then the gateway, then grimoire (only the LAN share is affected), then the new services.

| Phase | What | Public downtime | Rough time |
|---|---|---|---|
| 0 | Prep (tonight) | none | 30 min |
| 1 | Back up staff + grimoire | **starts here** | 30–60 min |
| 2 | Reinstall staff on the RAID1, restore | continues | 45–90 min |
| 3 | Deploy gateway | **ends here** | 5 min |
| 4 | Grimoire → ZFS RAIDZ1 | LAN share only | 1–2 h + ZFS build + resilver |
| 5 | Nextcloud + Authentik | none | 30 min |
| 6 | Lock admin SSH to WireGuard, router DNS | none | 20 min |

Every phase has a rollback, and **no old drive is wiped today** — they sit in a drawer for two weeks.

Commands are fish, run from Desktop in `~/infra` unless they say otherwise. Admin SSH is `ssh -p 2222 aaron@<host>`.

---

## Phase 0 — prep (tonight)

- [ ] Review the diff, then commit it on a branch. **Flakes only see tracked files**, so commit before any deploy or install.
  ```fish
  git switch -c storage-migration
  git add -A; git commit -m "storage migration: RAID, drop stalwart, lan dns, wg admin, nextcloud, authentik"
  ```
- [ ] Check every host still evaluates:
  ```fish
  for h in staff grimoire gateway desktop framework13
    echo $h; nix eval --raw .#nixosConfigurations.$h.config.system.build.toplevel.drvPath; echo
  end
  ```
- [ ] Copy `RESTIC_PASSWORD` from `/tmp/claude-1000/-home-aaron-infra/0193ce0c-5b31-45fd-8fb3-24e73d19fc37/scratchpad/restic-staff.json`
      into your password manager, then delete the file. Without it, backups can't be restored.
- [ ] Find a backup disk with room (step 0 of the backup runbook prints sizes) and set `BK` to a folder on it.
- [ ] Write a NixOS minimal ISO to a USB stick (only needed for plan B in phase 2).
- [ ] Label the drives with a marker: grimoire's old NVMe = **OLD-GRIMOIRE**, staff's old NVMe = **OLD-STAFF**.
- [ ] Cloudflare DNS: add `auth` and `cloud` A records → `51.68.220.132` (same as `pds`/`knot`).
      Delete the old mail records for `notify.aaronf86.tech` (MX, SPF, DKIM, `mail.notify`).
- [ ] Have your VPS provider's web console login handy (phase 6 changes how you reach the gateway).

---

## Phase 1 — back up (downtime starts)

Follow **`docs/runbooks/pre-migration-backup.md` steps 0–5** exactly. In short:

1. Stop `nixos-upgrade.timer` on staff and grimoire, then stop staff's services.
2. Optional: a last `pg_dump` of Stalwart, if there's any mail worth keeping.
3. `staff.tar.zst` (all of `/var/lib` except Docker, plus `/etc/ssh` and homes), `grimoire.tar.zst` (eMMC state),
   and `grimoire-pds-blobs.tar.zst`.
4. Verify the archives and write `SHA256SUMS`. Put the small critical files on a second device too.

**Leave staff's services stopped.** Anything written after the backup would be lost by the restore.

**Rollback:** run step 6 of the runbook to restart everything. Nothing has changed yet.

---

## Phase 2 — reinstall staff

### 2a. Get the new drive IDs

**Plan A — the 2 TB drives fit alongside the old NVMe** (preferred: the old OS stays bootable as a fallback):
fit them, boot staff normally, then
```fish
ssh -p 2222 aaron@staff 'ls -l /dev/disk/by-id/ | grep -v part'
```
**Plan B — no free slots:** pull **OLD-STAFF**, fit the 2 TB drives, and boot the USB installer.
On its console run `passwd` (for root), then `ls -l /dev/disk/by-id/`.

Put the two IDs into `hosts/staff/disk-config.nix` (replacing `TODO1`/`TODO2`) and commit.
**Check twice that neither ID is the old NVMe**, because disko wipes whatever is listed.

### 2b. Install

```fish
# Plan A: nixos-anywhere kexecs the running system into an installer (which listens on port 22)
nix run github:nix-community/nixos-anywhere -- --flake .#staff --phases kexec,disko,install \
  --target-host aaron@192.168.1.241 --ssh-port 2222 --post-kexec-ssh-port 22

# Plan B: straight at the USB installer (already a live system, so skip kexec)
nix run github:nix-community/nixos-anywhere -- --flake .#staff --phases disko,install --target-host root@192.168.1.241
```

Leaving out the `reboot` phase leaves the new system mounted at `/mnt`, so the state can be restored **before** it ever boots.
Services then come up on their real data, not on empty state.

### 2c. Restore state into /mnt

```fish
# Everything from /var/lib (minus Stalwart + its old cert), SSH host keys, homes.
# --numeric-owner works because var/lib/nixos (the uid map) comes back too, so uids match.
zstd -dc $BK/staff.tar.zst | ssh root@192.168.1.241 \
  'tar -C /mnt -xpf - --numeric-owner --xattrs --acls --exclude=var/lib/stalwart --exclude=var/lib/acme \
  --exclude=var/lib/mysql --exclude=var/lib/redis-pterodactyl'

# PDS blobs: from grimoire's old share into PDS's data dir, owned like the rest of it
zstd -dc $BK/grimoire-pds-blobs.tar.zst | ssh root@192.168.1.241 '
  set -e; d=/mnt/var/lib/bluesky-pds
  mkdir -p $d/blocks
  tar -C $d/blocks --strip-components=4 -xpf -
  chown -R $(stat -c %u:%g $d) $d/blocks'

ssh root@192.168.1.241 'ls -l /mnt/var/lib/sops-nix/keys.txt /mnt/etc/ssh/ssh_host_ed25519_key; du -sh /mnt/var/lib/*'
ssh root@192.168.1.241 reboot
```

### 2d. Check staff

The host key is unchanged, so SSH shouldn't show a "host key changed" warning. If it does, the restore went wrong; stop there.
```fish
ssh -p 2222 aaron@staff 'cat /proc/mdstat; systemctl --failed; systemctl is-active openbao knot spindle soft-serve bluesky-pds nginx unbound authentik'
ssh -p 2222 aaron@staff 'curl -s localhost:3000/xrpc/_health; curl -sI localhost:5555 | head -1'
```
The root mirror should show `[UU]`, and `diff -r /boot /boot-fallback` should print nothing. `restic-backups-grimoire` will fail until phase 4, which is expected.
The wildcard certificate is issued in the background (`journalctl -u acme-aaronf86.tech`).

**Rollback:** Plan A: choose the old NVMe in the firmware boot menu. Plan B: put **OLD-STAFF** back.
Either way the old system boots with its pre-backup state.

---

## Phase 3 — gateway (downtime ends)

This has to wait until after phase 2: haproxy now sends public SSH to staff's port 22, which only listens on the new config.
```fish
nix run .#colmena -- apply --impure --on gateway
```
From outside (e.g. a phone off Wi-Fi), check:
- `https://pds.aaronf86.tech/xrpc/_health`, `https://knot.aaronf86.tech`, `https://git.aaronf86.tech`
- `ssh -T git@knot.aaronf86.tech` works, and `ssh aaron@knot.aaronf86.tech` is **refused** (port 22 accepts only `git`)

**Rollback:** `git revert` the gateway changes and `nix run .#colmena -- apply --impure --on gateway`.

---

## Phase 4 — grimoire → ZFS RAIDZ1

Four 4 TB drives: two new (`…beb5`, `…c0e5`), staff's old one (`…dbb5`) and grimoire's old data drive (`…da75`).
The pool is built **degraded** on the first three plus a sparse placeholder file, the data is copied off `…da75`,
and only then is `…da75` wiped and swapped in for the placeholder. The old drive keeps every byte until the copy is verified.

Layout (`hosts/grimoire/disk-config.nix`): pool `storage`, datasets `share` (Samba, snapshotted), `nextcloud` (snapshotted),
`postgresql` (16K records) and `backups`, all legacy-mounted under `/mnt/storage` with `nofail`.
Services wait for their own dataset, so a missing pool never means writes to the eMMC.

1. **Freeze and size** (fish, from Desktop). `--apparent-size` because btrfs compresses.
   ```fish
   ssh -p 2222 aaron@grimoire 'sudo systemctl stop samba-smbd nixos-upgrade.timer; sudo du -sh --apparent-size /mnt/storage'
   sudo umount /mnt/storage   # on desktop
   ```
2. **Fit staff's old drive** in the free slot and boot. Check all four IDs, and that `…da75` is still the btrfs one:
   ```fish
   ssh -p 2222 aaron@grimoire 'ls -l /dev/disk/by-id/ | grep nvme-eui | grep -v part; sudo blkid /dev/disk/by-id/nvme-eui.*-part1'
   ```
   If staff's drive isn't `…dbb5`, fix `nvme3` in `disk-config.nix` before going on.
3. **Deploy ZFS** before touching a drive. This builds the ZFS module on grimoire (20–40 min the first time).
   The old btrfs mount goes away with this deploy; Samba, Nextcloud and restic stay stopped until their datasets exist.
   ```fish
   nix run .#colmena -- apply --impure --on grimoire
   ssh -p 2222 aaron@grimoire 'sudo modprobe zfs && zfs version && hostid'   # hostid must print 5b86421b
   ```
   If the module won't build: stop here, `git revert` the ZFS commit, and fall back to md RAID5 + btrfs. Nothing is lost.
4. **Create the degraded pool** (bash, on grimoire, `sudo -i`). Same partitions and options disko would use:
   ```bash
   e=/dev/disk/by-id/nvme-eui.00000000000000000026b7283
   for n in 1:c87beb5 2:c87c0e5 3:b03dbb5; do i=${n%%:*} d=$e${n#*:}
     wipefs -a $d; sgdisk --clear --new=1:0:-0 --change-name=1:disk-nvme$i-zfs --typecode=1:8300 $d; done
   udevadm settle
   truncate -s $(blockdev --getsize64 ${e}c87beb5-part1) /var/tmp/placeholder.img   # sparse: uses no space
   zpool create -f -o ashift=12 -o autotrim=on \
     -O acltype=posixacl -O atime=off -O com.sun:auto-snapshot=false -O compression=zstd -O mountpoint=legacy -O xattr=sa \
     storage raidz1 ${e}c87beb5-part1 ${e}c87c0e5-part1 ${e}b03dbb5-part1 /var/tmp/placeholder.img
   zpool offline storage /var/tmp/placeholder.img && rm /var/tmp/placeholder.img
   zfs create -o mountpoint=legacy -o recordsize=1M -o com.sun:auto-snapshot=true storage/share
   zfs create -o mountpoint=legacy -o com.sun:auto-snapshot=true storage/nextcloud
   zfs create -o mountpoint=legacy -o recordsize=16K storage/postgresql
   zfs create -o mountpoint=legacy -o recordsize=1M storage/backups
   zpool status storage    # DEGRADED, placeholder OFFLINE: expected
   systemctl start mnt-storage-share.mount mnt-storage-nextcloud.mount mnt-storage-postgresql.mount mnt-storage-backups.mount
   findmnt -R /mnt/storage
   ```
5. **Copy** from the old drive, read-only. The `storage` subvolume Samba served was nearly empty; the data sat at the
   btrfs top level (`recovery.img`, `staff/`, `pds/`). Only the newest Forge backup is kept. The rest goes with the wipe:
   `recovery.img` (953 GB ddrescue image), the older Forge backup, `client-tos.pdf`, and both `pds` copies (now on staff).
   ```bash
   src=staff/backups/minecraft-forge/2026-04-16-001220
   mkdir -p /mnt/old && mount -o ro,subvolid=5 ${e}b03da75-part1 /mnt/old
   mkdir -p /mnt/storage/share/$src
   rsync -aHAX --info=progress2 /mnt/old/$src/ /mnt/storage/share/$src/
   rsync -aHAXn --checksum /mnt/old/$src/ /mnt/storage/share/$src/ | head   # nothing listed = identical
   umount /mnt/old
   ```
6. **Swap the placeholder for the old drive.** Only after step 5 lists nothing. This is the point of no return for the old btrfs copy.
   ```bash
   wipefs -a ${e}b03da75-part1; wipefs -a ${e}b03da75
   sgdisk --clear --new=1:0:-0 --change-name=1:disk-nvme4-zfs --typecode=1:8300 ${e}b03da75; udevadm settle
   zpool replace storage /var/tmp/placeholder.img ${e}b03da75-part1
   zpool status storage    # resilvering; only real data is copied, everything works meanwhile
   ```
7. **Bring services up** and check:
   ```fish
   ssh -p 2222 aaron@grimoire 'sudo systemctl start samba-smbd restic-rest-server postgresql phpfpm-nextcloud nextcloud-setup; systemctl --failed; zfs list'
   sudo mount /mnt/storage   # on desktop
   ssh -p 2222 aaron@staff 'sudo systemctl start restic-backups-grimoire && journalctl -u restic-backups-grimoire -n 20'
   ```

**Until the resilver finishes there's no redundancy**, and after step 6 the old copy is gone. If that worries you,
copy the irreplaceable parts of the share somewhere else before step 6.

**Rollback before step 6:** `zpool destroy storage`, `git revert` the grimoire changes, deploy, and the old btrfs drive mounts as before.

---

## Phase 5 — Nextcloud + Authentik

Both came up with phases 2 and 4. All that's left is first-time setup.

**Authentik** (staff):
1. Open `https://auth.aaronf86.tech/if/flow/initial-setup/` and set the `akadmin` password **immediately**.
   Until you do, anyone who reaches the page can claim it.
2. Create a provider: *Applications → Create with provider → OAuth2/OIDC*, name `nextcloud`,
   redirect URI `https://cloud.aaronf86.tech/apps/user_oidc/code`. Note the client ID and secret.
3. No email is configured (Stalwart is gone), so password-reset emails won't send. Set up an SMTP relay later if you need it.

**Nextcloud** (grimoire):
```fish
ssh -p 2222 aaron@grimoire
sudo nextcloud-occ status
sudo nextcloud-occ user:add aaron                     # prompts for a password: this is your break-glass login
sudo nextcloud-occ group:adduser admin aaron
sudo nextcloud-occ user_oidc:provider authentik \
  --clientid=<id> --clientsecret=<secret> \
  --discoveryuri=https://auth.aaronf86.tech/application/o/nextcloud/.well-known/openid-configuration
```
Then open `https://cloud.aaronf86.tech`, log in through Authentik, and check *Administration → Overview* for warnings.

---

## Phase 6 — lock down admin SSH, router

1. Deploy the workstations, which brings up their tunnel and generates a key on each:
   `sudo nixos-rebuild switch --flake .#desktop` (and the same for `framework13` on the laptop).
2. On each: `sudo wg show wg0 public-key`. Paste the keys into `adminPeers` in `hosts/gateway/services/tunnel.nix`.
3. **Keep an SSH session to the gateway open**, then `nix run .#colmena -- apply --impure --on gateway`.
   Open a second terminal: `ssh -p 2222 aaron@10.44.0.1` should work, and `ssh -p 2222 aaron@51.68.220.132` should time out.
4. In `flake.nix`, change the gateway's `deployment.targetHost` to `"10.44.0.1"` and commit.
5. **Router:** reserve `192.168.1.241` (staff) and `192.168.1.115` (grimoire) in DHCP. Set DHCP DNS to **only** those two.
   Turn off ISP DNS being handed out over IPv6.
   Check from a LAN machine: `dig +short cloud.aaronf86.tech` → `192.168.1.241`.

**Rollback:** the VPS web console. Empty `adminPeers` and redeploy, and public 2222 reopens.

---

## Done when

- [ ] `systemctl --failed` is empty on all four servers
- [ ] Both arrays are healthy: staff `cat /proc/mdstat` shows `[UU]`, grimoire `zpool status` is ONLINE with no errors (wait for the resilver)
- [ ] The first restic snapshot exists: `ssh -p 2222 aaron@staff 'sudo restic-grimoire snapshots'`
- [ ] PDS, Knot, git, cloud and auth all load from outside **and** from the LAN
- [ ] Merge `storage-migration` into `main` and push
- [ ] **In two weeks:** wipe OLD-STAFF and OLD-GRIMOIRE, and remove `cloudflare-staff`'s old Stalwart scope if it had one

## Not today (from the security review)

Turn off Avahi on the gateway · Samba logins instead of guest · an offline personal sops key ·
limit the Haskell caches to workstations · retire the OpenBao root token · scope the Cloudflare tokens ·
off-site copy of the critical backups · prune old snapshots on grimoire.
