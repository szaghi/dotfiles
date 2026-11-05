---
title: ssh
---

# ssh

The `ssh/` package holds one file, `ssh/.ssh/config`: the ssh client configuration. Keys, `known_hosts` and
`authorized_keys` are never part of it; they stay real, untracked files in `~/.ssh/`. The comments in the file record
why each setting is there, with the measurements that motivated it.

## Install

```bash
mkdir -p -m 700 ~/.ssh                # must exist before the first stow
bash ~/dotfiles/dotify.sh ssh
```

The result is a single symlink, `~/.ssh/config`, pointing into the repository.

## Structure

| Block | What it sets |
|---|---|
| `Host *` | `ServerAliveInterval 30`, `ServerAliveCountMax 6`, `TCPKeepAlive yes` |
| `astrobit`, `quark` | reached as `<name>.local` through mDNS |
| `adam` | `adam.local` on port `2222` |
| cluster login aliases | one `Host` alias per HPC login, with its user name; one of them pins host keys in a dedicated `known_hosts` file and forwards X11 untrusted |

`.bashrc` reads the `Host` lines (wildcards excluded) and offers them as completions for `ssh`, `scp` and `sftp`.

```bash
ssh astrobit
scp results.h5 adam:
```

## Conventions

- **Keepalive comes from `ServerAliveInterval`, not `TCPKeepAlive`.** A NAT or firewall on the path drops an idle
  flow's state after one or two minutes without sending a reset, and the session freezes. The kernel's TCP keepalive
  starts after two hours, too late. An SSH-level ping every 30 s keeps the state alive; after 6 missed replies
  (about 3 minutes) the client gives up instead of hanging.
- **Home machines are always `<name>.local`.** Never the bare hostname and never a fixed IP: the machines move
  between the home network and a phone hotspot, and mDNS announces the name on whichever link they are on. The home
  router's DNS answers a bare name with the right address mixed into a list of unrelated leases, so a bare-name
  connection can hang on someone else's device.
- **adam listens on 2222.** It is a WSL2 distro with mirrored networking: port 22 on that address belongs to the
  Windows OpenSSH server.
- **Round-robin login nodes get pinned keys, not disabled checking.** When a login name round-robins over nodes with
  different host keys, the fix is a dedicated `UserKnownHostsFile` holding every node's key under the hostname, with
  `StrictHostKeyChecking yes`. The config comment carries the `ssh-keyscan` recipe and the fingerprints to check
  against. That `known_hosts` file is site state and is not tracked.
- **X11 forwarding is untrusted.** `ForwardX11Trusted no` is set explicitly: Ubuntu's OpenSSH defaults it to `yes`,
  which makes `-X` behave like `-Y`.

## Things to know

::: warning Create `~/.ssh` first
If `~/.ssh` does not exist, stow links the whole directory into the repository. Every key generated afterwards
(`ssh-keygen`) and every `known_hosts` entry then lands inside `~/dotfiles/ssh/.ssh/`, one `git add` away from a
public repository. Create the directory before stowing, as above, and check that `~/.ssh` itself is not a symlink.
:::

- **Never add keys or `known_hosts` to the package.** Host keys are per-site state; pinning stale keys across machines
  defeats the check.
- **A failing `ping` to the cluster is not a fault.** ICMP is filtered at one of the sites while TCP/22 works.
