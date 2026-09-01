# dnscrypt-proxy: background service, NOT system-wide DNS

## Goal
- dnscrypt-proxy runs as a background daemon (`multi-user.target`, `Restart=always`,
  binds only `127.0.0.1:53`).
- System DNS must NOT be forced through it automatically. User toggles via Noctalia
  dns-switcher plugin (`custom_1 = "dnsncrypt-proxy = 127.0.0.1"`).

## Facts (verified)
- Your local commit `94b5469 feat: enable encrypted dns` already sets
  `services.dnscrypt-proxy.enable = true` in `hosts/nixos/default.nix`.
- The nixpkgs module (rev 9fbb54b) injects `networking.nameservers = lib.mkDefault [ "127.0.0.1" ]`
  when enabled (module line 87) -> that IS the system-wide auto-hijack via NixOS resolvconf.
- VM not yet deployed (still `ad60080`, `enable = lib.mkForce false`). DNS currently
  `192.168.122.1` (DHCP -> NM -> resolvconf), `:53` free, systemd-resolved inactive.
- Module otherwise pure daemon: DynamicUser, hardened sandbox, no firewall rule,
  `wantedBy = multi-user.target`.

## Edits
1. `hosts/nixos/default.nix`:
   - `networking.nameservers = lib.mkForce [ ];` (defeats module mkDefault; system DNS
     stays DHCP) + comment.
   - Replace stale TEMP comment (lines 69-72) with the background-only description.

## Deploy + verify
- rsync local -> VM (`sshpass`, exclude `.git`), VM `git add -A` + commit `wip`,
  `sudo nixos-rebuild switch --flake .#nixos`.
- `systemctl is-active dnscrypt-proxy` -> active.
- `ss -tuln | grep :53` -> 127.0.0.1:53 UDP + TCP.
- `cat /etc/resolv.conf` -> still `192.168.122.1`, NO 127.0.0.1.
- `dig @127.0.0.1 example.com +short` -> resolves via proxy.
- `dig example.com +short` -> resolves via system path.

## Commit
- Local commit: `fix(nixos): run dnscrypt in background, keep system DNS on DHCP`
  (user approved).