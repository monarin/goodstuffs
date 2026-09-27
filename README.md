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

After bootstrap, start a new shell and run:

```bash
renew_s3df_key
```

Complete Stanford SSO and Duo in the dedicated Chrome window if prompted.
The command verifies `sdflogin`, `psbuildrc`, and `sdfiana` before it finishes.

NERSC `sshproxy` is installed separately from the official macOS universal
package at <https://portal.nersc.gov/cfs/mfa/>. After installation, run
`sshproxy -f` and complete the browser login to create a fresh per-Mac NERSC
credential.

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
