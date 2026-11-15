# sdfiana SSH-agent lifetime refresh review

## Scope

- Make renewal mode re-add `sdfiana`'s encrypted SSH identity with a fresh
  24-hour lifetime even when that identity is already loaded.
- Preserve the noninteractive, read-only behavior of `ssh_agent_start --status`.
- Keep the passphrase in Mona's interactive terminal and update user and
  personal-skill documentation.

## Exclusions

- Do not run a passphrase-bearing command from an agent-controlled session.
- Do not copy, inspect, register, or commit private-key or credential material.
- Do not change S3DF registration, Kerberos, NERSC, or psbuildrc behavior.

## Acceptance checks

- Renewal calls `ssh-add -t 24h KEY` whether the key is absent or already loaded.
- Status mode never calls the mutating `ssh-add` form.
- Tests and `git diff --check` pass.
- The matching personal-skill update has an immutable revision.
- Independent review finds no unresolved blocking issue in the latest code
  commit.
