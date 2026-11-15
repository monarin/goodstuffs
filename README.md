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
- the Mac's NERSC `sshproxy` key through password plus OTP entered in Terminal;
- `sdfiana`'s encrypted local SSH key in its host-local agent, plus its
  Kerberos cache;
- `sdfiana`'s separate NERSC key through password plus OTP entered in the
  terminal; and
- the host-local Kerberos cache on `psbuildrc`.

Use `renew_daily_access --status` for a read-only check. The renewal command
keeps passphrase and password-plus-OTP prompts attached to the current terminal
and continues checking later independent stages after a failure.

The Mac-only S3DF gateway step remains available separately:

```bash
renew_s3df_key
```

Complete Stanford SSO and Duo in the dedicated Chrome window if prompted.
The command verifies `sdflogin`, `psbuildrc`, and `sdfiana` before it finishes.

On `sdfiana`, the individual commands are:

```bash
ssh_agent_start
renew_sdf_krb
```

`ssh_agent_start` invokes `ssh-add -t 24h`, which asks for the passphrase
protecting `~/.ssh/id_ed25519` and resets its lifetime even when the identity is
already loaded. The daily workflow does not copy this key anywhere; the Mac
S3DF registration already provides access to `sdflogin`, `sdfiana`, and
`psbuildrc`.

On `psbuildrc`, no daily SSH-key or agent action is required. Run only
`renew_sdf_krb` when working with its host-local Kerberos ticket.

`renew_sdf_krb` first tries password-free renewal; if the ticket is expired,
non-renewable, or past its renewal deadline, it prompts for a fresh one.
Each command supports `--status` for a read-only check.

The workflow implementation must be present in `~/goodstuffs` on both remote
homes. Update the `sdfiana` and `psbuildrc` checkouts independently, preserving
any host-local changes, then start a new shell (or source `~/goodstuffs/bashrc`)
before using the command from the Mac.

NERSC `sshproxy` is installed separately from the official packages at
<https://portal.nersc.gov/cfs/mfa/>. Run `renew_nersc_key` on the Mac and in an
interactive `sdfiana` terminal, entering NERSC password plus OTP independently
for each. The two machines receive separate credentials.

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
