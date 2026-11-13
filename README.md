# goodstuffs

Personal shell, SSH, S3DF, and Codex helpers.

## Bootstrap a Mac

Clone this repository at `~/goodstuffs`, then run:

```bash
~/goodstuffs/bin/bootstrap-mac.sh
```

The bootstrap is non-destructive and repeatable. It:

- adds the shell setup without replacing existing shell files;
- installs the portable SSH host configuration under `~/.ssh/config.d`;
- installs the Node dependency used by the S3DF daily-key helper;
- clones or updates `~/codex-skills` and links every personal skill into
  `~/.codex/skills`;
- writes the generated S3DF SSH include without creating or copying private
  credentials.

It does not copy private keys, browser profiles, tokens, or Codex-generated
machine configuration. Create credentials independently on each Mac.

After bootstrap, start a new shell. The normal daily entry point is:

```bash
renew_daily_access
```

This interactive workflow prepares each independent credential in order:

- S3DF gateway registration on the Mac;
- the Mac's NERSC `sshproxy` key through browser federated login;
- the encrypted SDF SSH key and host-local Kerberos cache on `sdfiana`;
- `sdfiana`'s separate NERSC key through a URL opened on the Mac; and
- the unencrypted SDF SSH key registration and host-local Kerberos cache on
  `psbuildrc`.

Use `renew_daily_access --status` for a read-only check. The renewal command
keeps passphrase, password, and federated-login prompts attached to the current
terminal and continues checking later independent stages after a failure.

The Mac-only S3DF gateway step remains available separately:

```bash
renew_s3df_key
```

Complete Stanford SSO and Duo in the dedicated Chrome window if prompted.
The command verifies `sdflogin`, `psbuildrc`, and `sdfiana` before it finishes.

On `sdfiana`, the individual commands are:

```bash
ssh_agent_start
renew_sdf_key
renew_sdf_krb
```

`ssh_agent_start` invokes `ssh-add`, which asks for the passphrase protecting
`~/.ssh/id_ed25519`. `renew_sdf_key` calls that helper automatically before it
refreshes the public-key registration on `jump.slac.stanford.edu`.

On `psbuildrc`, `~/.ssh/id_rsa` is a separate unencrypted key. Run
`renew_sdf_key` and `renew_sdf_krb`; the key-renewal helper detects that no
passphrase is required and skips the agent.

`renew_sdf_krb` first tries password-free renewal; if the ticket is expired,
non-renewable, or past its renewal deadline, it prompts for a fresh one.
Each command supports `--status` for a read-only check.

The workflow implementation must be present in `~/goodstuffs` on both remote
homes. Update the `sdfiana` and `psbuildrc` checkouts independently, preserving
any host-local changes, then start a new shell (or source `~/goodstuffs/bashrc`)
before using the command from the Mac.

NERSC `sshproxy` is installed separately from the official packages at
<https://portal.nersc.gov/cfs/mfa/>. Run `renew_nersc_key --fedid` on the Mac,
or `renew_nersc_key --fedid --no-browser` on `sdfiana`, to create the separate
24-hour credentials. The no-browser form prints a URL for completing Google
authentication on the Mac.

## SDF development workspace

`sdfwork` restores recent remote Codex development sessions in separate Apple
Terminal windows, with an optional tmux fallback. See
[docs/sdfwork.md](docs/sdfwork.md) for installation, usage, and troubleshooting.

## Manual dotfile setup

If you do not use the bootstrap script, add this line to `~/.bashrc`:

```bash
[ -f "$HOME/goodstuffs/bashrc" ] && . "$HOME/goodstuffs/bashrc"
```

Optionally link the Vim configuration:

```bash
ln -s "$HOME/goodstuffs/vimrc" "$HOME/.vimrc"
```
