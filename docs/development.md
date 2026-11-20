# Development

## Run

```bash
flutter pub get
flutter run -d linux        # or macos / windows
```

To try it without touching your real data, point it at a scratch folder:

```bash
mkdir -p /tmp/demo/usage-widget
NOW=$(date +%s)
echo "{\"session_id\":\"demo\",\"written_at\":$NOW,\"rate_limits\":{\"five_hour\":{\"used_percentage\":24,\"resets_at\":$((NOW+9000))},\"seven_day\":{\"used_percentage\":78,\"resets_at\":$((NOW+250000))}}}" > /tmp/demo/usage-widget/demo.json
CLAUDE_CONFIG_DIR=/tmp/demo flutter run -d linux
```

## Test

```bash
flutter analyze && flutter test
(cd bridge && dart analyze && dart test)
```

## Preview the UI without a screen

```bash
PREVIEW_OUT=/tmp/previews flutter test tool/preview_test.dart
python3 tool/make_screenshots.py /tmp/previews     # README images
python3 tool/make_icon.py                          # app icon
```

Add `--enable-impeller` to render with the app's real renderer.

## Build

- Linux: `./build_linux.sh`, then `./install_linux.sh`.
- macOS and Windows: `.github/workflows/build.yml` (it runs on every push to
  `main`, or run it manually). These builds compile but have **not been
  run**. The bridge must sit next to the app executable.

## Release

Releases are automatic: every push to `main` that changes more than docs runs
`.github/workflows/build.yml`, which builds the three packages and publishes
them with a `SHA256SUMS` file. There is no tag to push and nothing to bump.

- **Version:** the workflow numbers the release, as the next patch after the
  latest release (`v0.1.0` → `v0.1.1`). To ship a bigger step, raise `version:`
  in `pubspec.yaml` past the latest release (say `0.2.0`) and merge; that exact
  version is used once, then patches continue from it.
- **Stamping:** the workflow writes the chosen version into `pubspec.yaml` and
  `AppConstants.version` in the build only, never committed. The app compares
  `AppConstants.version` with the latest release to decide whether to update,
  so keep that line a plain `static const version = 'X.Y.Z';`.
- **Notes:** release notes are generated from the merged commits and PRs.
- **Checks:** the build runs `flutter analyze`, the app and bridge tests, and
  fails (publishing nothing) if any fail. Merge only what CI has passed.
- **Users:** the app checks for the latest release at start and every six
  hours and installs it on macOS and Linux (see the README's Update section).
  Asset names carry no version, so `releases/latest/download/<name>` always
  serves the newest; `install.sh` and the app both depend on that.
- The Linux package is built on Ubuntu 22.04 so it runs on distributions with
  an older glibc.

## Platform notes

- Linux uses the X11 backend (XWayland on Wayland sessions), because Wayland
  cannot keep a window above others or restore its position.
- Linux tray needs `libayatana-appindicator3-dev`; GNOME needs the
  AppIndicator extension to show it.
- macOS: App Sandbox is off so the app can read the Claude config folder.
  Unsigned builds show a Gatekeeper warning.
