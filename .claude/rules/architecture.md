# Architecture

Simple now, room to grow: rules and calculations on plain values live in the core; AppKit, AVFoundation and side effects live in the app.

## Targets

| Target | Kind | May import | Holds |
|---|---|---|---|
| `PlayerCore` | library | Foundation, CoreGraphics | Rules and calculations: `PlaybackRules`, `EndBehavior`, `PlaybackTime`, `VideoGeometry`, `WindowFitting` |
| `Player` | executable | AppKit, AVFoundation, AVKit, PlayerCore | App shell: startup, menu, window controller, views, localized strings |
| `PlayerCoreTests` | test | PlayerCore, Testing | One `<Concept>Tests.swift` per core file, plus `CoreImportsTests` |
| `LocalizationTests` | test | Foundation, Testing | Checks `Resources/` and `Sources/` through `#filePath`; depends on no target |

- No `products:` entry and no `.library` product: nothing outside the package uses `PlayerCore`.
- Add a new target only when code gets a second consumer.

## PlayerCore

- API uses `package` access, never `public`. Declare `package init()` explicitly and add `Sendable` explicitly to every type.
- No AppKit or AV frameworks, no I/O or global state (UserDefaults, FileManager, NotificationCenter, Bundle, clocks), no localized strings (`String(localized:)`, `NSLocalizedString`). SwiftPM cannot restrict system imports, so `CoreImportsTests` enforces this; keep it green.
- Expected outcomes are returned as enums (`EndAction`, `PlaybackStart`), never thrown.
- `PlaybackRules` is the single owner of playback state and of the default end behavior. Its internal state stays `private`; tests check it through behavior.

## Player (app shell)

- `PlayerWindowController` is the only owner of `AVPlayer`, the load task, the observers and `PlaybackRules`. It asks the core what to do and does it, and it wires every target/action.
- Views take data and expose controls; they never reference the controller. `PlayerContentView` is the window's `contentView` and is the only file that imports AVKit.
- Display text for a core type goes to `<CoreType>+Text.swift` in the app target. Extension-only files are named `Type+Purpose.swift`.
- `Sources/Player/` stays flat until it has about 12 files; then group it into subfolders (for example `App/`, `Window/`, `Views/`) without changing modules or tests.

## Where new code goes

- A rule or calculation on plain values: `Sources/PlayerCore/<Concept>.swift` and `Tests/PlayerCoreTests/<Concept>Tests.swift`.
- Anything that touches AppKit, AVFoundation, files, preferences or timers, and every localized string: `Sources/Player/`.

## Localization

- Tables live in `Resources/<lang>.lproj/Localizable.strings` at the repo root, outside every target. `build.sh` copies them into the main app bundle; code reads them through `Bundle.main`. Never use SwiftPM resources (`Bundle.module`): AppKit picks the language of its own UI and the right-to-left layout from the main bundle's localizations.
- Format is `.strings`, not `.xcstrings`: `build.sh` has no String Catalog compile step.
- Every key exists in all 40 tables. A missing key shows the raw key, and a syntax error breaks the whole table.
- The literal in `String(localized:)` is the key. Interpolate only strings; each becomes `%@` in the key.
- A new language is a new `.lproj` folder plus its code in `supportedLanguages` in `LocalizationTests`.

## Tests

- Swift Testing, run with `swift test`. Tests import `PlayerCore` without `@testable`, so they use the same API as the app.
- Expected values are concrete numbers, never a copy of the formula. Rotations use explicit matrices with entries in {0, ±1}; non-integer geometry is compared with a 0.01 tolerance.
- Playback, layout and system panels are checked by hand with the checklist in `README.md`.

## Decisions and why

- **Core library + app, not one executable target with `@testable`:** the target graph keeps the core from depending on the app, and core tests do not load AppKit or `main.swift`. It costs one target.
- **Not the whole app in a library with a thin `main`:** that would put pure logic and AppKit code in one module, for the same cost.
- **No protocol over `AVPlayer`, view model, coordinator or DI container:** no second consumer; mocks of `AVPlayer` would test themselves.
- **`package` instead of `public`:** exactly the scope the app and the tests need, and it tells readers `PlayerCore` is not a reusable library.
