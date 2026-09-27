# sdfwork

`sdfwork` restores recent Codex development work on SDF from a Mac. It checks
daily S3DF SSH authentication, discovers the three most recent meaningful
development sessions from Codex metadata on `sdfiana`, resolves their Git
worktrees, and resumes each session.

## Components

- `bin/sdfwork`: Mac entry point and S3DF authentication preflight.
- `bin/sdfwork-terminal`: opens or focuses independent Apple Terminal windows.
- `bin/sdfwork-remote`: remote session discovery, Git resolution, resume, and
  optional tmux management. It remains Python 3.6 compatible for SDF.
- `bin/renew_s3df_key`: invokes the browser-backed key refresh and verifies all
  S3DF entry points.
- `bin/install-sdfwork`: installs Mac launchers and deploys the remote helper.

No Codex session identifiers are stored in these files. They are selected from
the live Codex index every time the launcher runs.

## Installation

From the Mac:

```bash
cd ~/goodstuffs
bin/install-sdfwork
```

Ensure `~/bin` is in `PATH`. The installer backs up changed local launchers
under `~/.local/state/sdfwork/backups/` and backs up the existing remote helper
beside `~/bin/sdfwork-remote` on `sdfiana`.

The default SSH alias is `sdfiana`. Override it for testing with:

```bash
SDFWORK_HOST=another-alias sdfwork --list
```

## Usage

```bash
sdfwork                 # open or focus three Apple Terminal windows
sdfwork --list          # show the current dynamic selection
sdfwork --tmux          # use the persistent tmux interface
sdfwork --tmux --reset  # reconstruct the tmux workspace
```

Each normal Terminal window runs Codex with `--no-alt-screen`, preserving the
Terminal scrollback buffer. Closing a window disconnects its TUI; the Codex
session remains resumable.

If the old `sdf-work` tmux session is running, the default launcher asks before
stopping it. This prevents two TUI processes from opening the same session.

## Task selection and worktree resolution

The remote helper reads `~/.codex/state_5.sqlite` and the referenced rollout
metadata. It filters utility and automated-review sessions, requires evidence
of development activity, and deduplicates continuations of the same task.

For each selected session it uses the recorded working directory and Git
metadata. If a worktree moved, it searches the repository's registered
worktrees. It never creates, deletes, resets, or changes a Git worktree or
branch. Branch drift is reported rather than corrected automatically.

## Authentication and approvals

Before every remote action, `sdfwork` runs `renew_s3df_key`. A fresh accepted
registration is reused. An expired or rejected registration opens the normal
Chrome SSO/Duo flow and the launcher waits for completion. It then independently
checks `sdflogin`, `psbuildrc`, and `sdfiana`.

Codex approval policy is deliberately not stored in this repository. The
remote machine may be configured separately in `~/.codex/config.toml`, for
example:

```toml
approval_policy = "on-request"
approvals_reviewer = "auto_review"
```

Review that setting against current Codex policy before applying it on another
machine.

## Troubleshooting

- Run `sdfwork --list` to verify authentication, selection, worktrees, and
  branches without opening Terminal windows.
- A Terminal `>` continuation prompt indicates a malformed or truncated shell
  command. Press Control-C, close that window, update/install the current
  scripts, and rerun `sdfwork`.
- If a worktree cannot be resolved, the task window opens a safe shell and
  reports the missing recorded path. It does not choose a replacement.
- Use `sdfwork --tmux` when network-disconnect persistence is more important
  than native Terminal scrollback.
- The remote helper prints the exact Codex retry command if resume exits.

## Security boundary

Do not commit any of the following:

- `~/.ssh`, private or public registration keys, certificates, or generated
  `s3df.conf`;
- `~/.codex`, authentication files, databases, rollouts, logs, or session IDs;
- browser profiles, SSO/Duo state, `.env` files, machine configuration, or
  generated backups.

The repository contains orchestration code only. Runtime state stays in the
user's home directories on the Mac and SDF.
