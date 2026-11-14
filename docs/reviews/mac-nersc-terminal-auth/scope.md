# Mac NERSC terminal authentication review

## Scope

- Make `renew_daily_access` renew the Mac's Perlmutter SSH credential through
  the terminal-based NERSC `Password+OTP:` flow.
- Preserve `--fedid` as an explicit opt-in supported by `renew_nersc_key`, but
  do not use it from the daily workflow.
- Keep `renew_daily_access --status` noninteractive.
- Update user and agent-skill documentation to describe the terminal flow.

## Exclusions

- Do not run a live renewal or collect credentials in an agent-controlled
  session.
- Do not change S3DF registration, remote renewal behavior, or SSH aliases.
- Do not include private keys, passwords, OTPs, tickets, or tokens in Git.

## Acceptance checks

- The daily renew path calls `renew_nersc_key` without `--fedid`.
- The status path still calls `renew_nersc_key --status`.
- The test suite and `git diff --check` pass.
- An independent reviewer finds no unresolved blocking issue in the latest
  implementation commit.
