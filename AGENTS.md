# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

A Flutter desktop widget that shows Claude Code usage. Two Dart packages:

- `/` — the Flutter app (`claude_usage_widget`).
- `bridge/` — `usage_bridge`, a tiny CLI that Claude Code runs as its status
  line command. The app also imports it as a path package for shared helpers.

Data flow: Claude Code → `usage_bridge` → JSON records in
`<claude config>/usage-widget/` → the app. The app's only network request is the update check in
`lib/data/services/update_service.dart` (the latest release's version number,
user-switchable in Settings). Do not add any other network call.

## Commands

```bash
flutter pub get
flutter analyze                 # must report "No issues found!"
flutter test                    # app tests
(cd bridge && dart analyze && dart test)
./build_linux.sh                # bridge + release build, bundled together
PREVIEW_OUT=/tmp/p flutter test tool/preview_test.dart   # render UI to PNG
```

Run all of the first four before saying a change is done.

## Layout

```
lib/
  config/     constants, logger
  domain/     immutable models (sealed UsageSnapshot), use cases
  data/       services (I/O, plugins) and repositories
  ui/core/    theme, motion, shared widgets
  ui/features/usage_widget/   cubit, state, views, layout
bridge/       status line command + shared record helpers
test/         mirrors lib/ (domain, data, ui)
tool/         preview renderer, icon and screenshot scripts
```

## Rules

- **State:** one `Cubit` (`UsageWidgetCubit`) with an immutable `Equatable`
  state. Views contain no logic and no I/O. The cubit coordinates; put new
  rules in a domain class and new mechanics in a collaborator (see
  `AlertPolicy`, `WindowMorpher`).
- **Layers:** imports point inwards only, `ui → data → domain → config`.
  `test/architecture_test.dart` enforces it. JSON parsing belongs in a
  mapper under `data/models/`, never in a domain model.
- **Dependencies:** construct services in `app_dependencies.dart` and inject
  them. Pick per-OS implementations there, not inside the classes.
  Anything that touches a plugin or the OS sits behind an interface in
  `data/services/` so the cubit can be tested with fakes.
- **Models:** add a new account type as a new `UsageSnapshot` subclass and let
  the compiler find every `switch` that must handle it.
- **Errors:** catch specific exception types and log with `logWarning`. No
  empty or untyped `catch`. The bridge must always exit 0.
- **Lints:** strict casts, inference and raw types; every public member is
  documented. Use `package:` imports in `lib/`.
- **Sizes:** card and window sizes live in `WidgetLayout`. The window is
  larger than the card by `shadowMargin`; if you change the pill size, update
  the default size in `linux/runner/my_application.cc` too.
- **Text:** use `AppText.style`. Pass `tabular: true` only for values that
  change in place; it widens hyphens in labels.

## Verifying UI changes

Do not report a UI change as working from code alone. Render it:

```bash
PREVIEW_OUT=/tmp/p flutter test tool/preview_test.dart            # test renderer
PREVIEW_OUT=/tmp/p flutter test --enable-impeller tool/preview_test.dart
```

Then look at the PNGs. Layout tests load the real font (`loadAppFont`), so an
overflow in `test/ui/views_test.dart` is a real overflow.

## Gotchas

- `window_manager` is pinned to 0.5.x. The 0.6 line ignored window sizes on
  GNOME/Wayland during development.
- `tray_manager` is used through `legacy.dart`; it needs
  `libayatana-appindicator3-dev` to build on Linux.
- Rate limits only change when Claude Code receives an API response. Record
  recency is not data freshness; see `AggregateUsage` before changing how
  sessions are merged.
- CI pins Flutter 3.50.0. Newer stable releases add lints that fail
  `flutter analyze`; bump the pin and fix them in the same change.
- macOS and Windows build in CI but have never been run. Say so in anything
  you write about them.
- Linux prefers the X11 backend (`linux/runner/main.cc`): Wayland cannot keep
  a window above others or restore its position.
- Regenerate README images with `tool/make_screenshots.py` after visual
  changes.
