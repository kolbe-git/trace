# trace

> A personal running & fitness tracker for iOS — minimal, single-user, iCloud-synced.

`trace` is an iOS app for recording outdoor runs, indoor / treadmill runs, cycling
and walking. It records GPS routes, pace, heart rate, splits and elevation, syncs
across your own devices via iCloud (CloudKit), and writes finished workouts back
into Apple Health.

It's deliberately **single-user**: no accounts, no social feed, no leaderboard,
no ads, no analytics SDKs. Just you and your runs.

## Features

**Recording**
- Outdoor GPS tracking (CoreLocation, background-capable)
- Indoor / treadmill via CoreMotion pedometer, with manual distance correction
- Live metrics: duration, distance, current pace (or speed for cycling), heart rate
- Pause / resume / end with a two-step end confirmation to avoid mis-taps
- Chinese voice coach: start / every-kilometer / finish announcements

**History**
- Map route playback (MapKit), per-km pace chart and elevation curve (Swift Charts)
- Splits table, editable notes, delete

**Stats**
- Week / month / year summaries (distance, duration, count, avg pace)
- Trend charts and personal records (fastest 1 km / 5 K / 10 K, longest distance, longest duration)
- Achievements: cumulative mileage, streak

**Goals**
- Weekly or monthly distance / count goals with progress gauges

**Integrations**
- Apple Health: read heart rate & weight, write workouts + routes + energy
- iCloud (CloudKit) sync across devices

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full feature plan and phasing.

## Tech stack

- **Swift 5** (targeting Swift 6 concurrency where practical), **SwiftUI**
- **SwiftData** with **CloudKit** sync (private database)
- **iOS 18.0+**, built with the iOS 26 SDK in Xcode 26.1
- CoreLocation · MapKit · HealthKit · CoreMotion · Swift Charts · AVFoundation

## Project layout

```
trace/                         # repo root
├── docs/ROADMAP.md            # feature plan
└── trace/                     # Xcode project
    ├── Config/                # xcconfig (Team ID lives here, not in pbxproj)
    ├── trace.xcodeproj
    └── trace/                 # app source
        ├── App/               # entry point, RootView, OnboardingView
        ├── Shared/            # Models / Services / Components / Common
        └── Features/          # Record / History / Stats / Goals / Profile (MVC per feature)
```

Source is organized **business-first**, each feature split MVC-style. The Xcode
project uses **file-system synchronized groups** — drop files into the folders
on disk and they're picked up automatically; no `project.pbxproj` edits needed.

## Build & run

### 1. First-time setup — your Apple Developer Team ID

The repo does not ship a Team ID. Create your local override:

```bash
cp trace/Config/Local.xcconfig.example trace/Config/Local.xcconfig
# then edit trace/Config/Local.xcconfig and set DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

`Local.xcconfig` is gitignored, so it never leaves your machine. Find your Team
ID at <https://developer.apple.com/account> → Membership, or in
Xcode → Settings → Accounts → your Apple ID → Team.

### 2. Bundle ID & CloudKit container

If you're forking and want to run on a real device, you'll also need to change:

- `PRODUCT_BUNDLE_IDENTIFIER` in `trace/trace.xcodeproj/project.pbxproj` (currently `net.kolbe.app.trace`)
- The iCloud container identifier in `trace/trace/trace.entitlements` (currently `iCloud.net.kolbe.app.trace`)

Both should be set to something you own.

### 3. Build

Day-to-day, just open `trace/trace.xcodeproj` in Xcode and hit ⌘R.

From the command line (note: `xcode-select` typically points at the Command
Line Tools, so set `DEVELOPER_DIR` to the real Xcode):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

The simulator works for most flows; **heart rate and step-based indoor
distance need a real device** (and ideally a paired Apple Watch for HR).

## Architecture notes

- **MVC per feature**: each `Features/<Name>/` package has `Model/` (feature-local
  presentation types), `View/` (thin SwiftUI views), `Controller/` (an
  `@Observable` class that holds the screen's state and logic — the SwiftUI
  ViewModel role).
- Persisted SwiftData entities (`Workout`, `RouteSample`, `Split`, `Goal`,
  `UserProfile`) live in `Shared/Models/` and are shared across features.
- One `WorkoutRecorder` owns an in-progress session; it survives backgrounding
  and only persists to SwiftData on finish (samples buffered in memory).
- All distances are stored in meters and durations in seconds; conversion to
  km / mi happens at the display layer, reading the user's unit preference.

### CloudKit constraints on the SwiftData schema

CloudKit will refuse to sync the store at runtime if you break any of these:

- Every stored property must be optional **or** have a default value
- No `@Attribute(.unique)` — CloudKit doesn't support unique constraints
- Relationships must be optional and always have an inverse

## License

[MIT](LICENSE) — do what you want.

## Acknowledgements

Inspired by the simplicity of [Keep](https://www.gotokeep.com/)'s recording
experience, minus everything social.
