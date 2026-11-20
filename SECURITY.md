# Security

## What the app touches

- It reads JSON records from `<claude config>/usage-widget/`.
- With your consent (the **Status Line** switch) it edits the `statusLine`
  entry of Claude Code's `settings.json`, and keeps a backup of the previous
  value.
- Its only network request is an anonymous check of GitHub's public API for
  the latest release's version number, at start and every six hours. Nothing
  about you or your usage is sent. **Settings → Auto-update** turns it off.
- On macOS and Linux, installing an update runs the repository's `install.sh`,
  which verifies the download against the release's `SHA256SUMS`.
- If `lean-ctx` is installed, it runs `lean-ctx gain --json` once a minute and
  shows three numbers from the output. It sends nothing anywhere, and
  **Settings → lean-ctx Stats** turns it off.
- It does not read credentials or tokens.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's
**Security → Report a vulnerability** on this repository. You should get a
reply within a week.
