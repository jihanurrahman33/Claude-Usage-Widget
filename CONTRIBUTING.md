# Contributing

Thanks for helping. Bug reports, testing on macOS and Windows, and pull
requests are all welcome.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable).
2. On Linux: `sudo apt install libgtk-3-dev libx11-dev libxi-dev libayatana-appindicator3-dev libnotify-dev`.
3. `flutter pub get`

See [docs/development.md](docs/development.md) for running, testing and
previewing the UI.

## Before you open a pull request

```bash
flutter analyze && flutter test
(cd bridge && dart analyze && dart test)
```

Both must pass. For UI changes, attach a screenshot or a render from
`tool/preview_test.dart`.

## Guidelines

- Keep the app free of network calls other than the update check, and away
  from credentials.
- Follow the structure in [docs/architecture.md](docs/architecture.md).
- Add or update tests with behaviour changes.
- Keep pull requests focused; one change per pull request.

## Reporting bugs

Use the bug template. The most useful things are your OS and desktop
(for example "Ubuntu 24.04, GNOME, Wayland"), your account type, and a
screenshot.

By contributing you agree that your work is licensed under the
[MIT License](LICENSE).
