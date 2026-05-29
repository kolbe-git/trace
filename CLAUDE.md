# trace

A personal running / fitness tracker for iOS, in the spirit of Keep — single-user, no
social feed, no accounts. Records outdoor runs, indoor/treadmill runs, cycling, and
walking; tracks GPS routes, pace, heart rate, and history; syncs across the owner's
devices via iCloud.

## Tech stack

- **Language:** Swift 5 (targeting Swift 6 concurrency where practical)
- **UI:** SwiftUI
- **Persistence:** SwiftData with **CloudKit** sync (private database)
- **Min OS:** iOS 18.0 (built with the iOS 26 SDK in Xcode 26.1). All APIs used are
  iOS 17-era (SwiftData, `@Observable`, new MapKit SwiftUI, Swift Charts, HealthKit
  builders). If you adopt an iOS 19+/26 API, gate it behind `if #available`.
- **Bundle ID:** `net.kolbe.app.trace`
- **Frameworks:** CoreLocation, MapKit, HealthKit, Swift Charts, CoreMotion (pedometer),
  AVFoundation (audio cues), ActivityKit (Live Activity), WidgetKit

## Layout

The Xcode project is nested one level down. Source is organized **business-first**, and
each business package is split MVC-style (`Model` / `View` / `Controller`):

```
trace/                         <- repo root (this file lives here)
├── CLAUDE.md
├── docs/ROADMAP.md            <- feature plan & phasing
└── trace/                     <- Xcode project dir
    ├── trace.xcodeproj
    └── trace/                 <- app source (synchronized root group)
        ├── App/               <- traceApp (entry + ModelContainer), RootView (5-tab TabView), OnboardingView
        ├── Shared/            <- cross-business layer
        │   ├── Models/        <- SwiftData @Model: Workout, RouteSample, Split, Goal, UserProfile, ActivityType
        │   ├── Services/      <- LocationManager, HealthKitManager, PedometerManager, AltimeterManager,
        │   │                     AudioCoach, WorkoutRecorder, WorkoutExporter (GPX/CSV 导出)
        │   ├── Components/    <- reusable SwiftUI views (RouteMapView)
        │   └── Common/        <- UnitPreference, MapStylePreference, Formatters, CalorieCalculator
        └── Features/          <- one package per business, each split MVC
            ├── Record/   {Model,View,Controller}
            ├── History/  {Model,View,Controller}
            ├── Stats/    {Model,View,Controller}
            ├── Goals/    {Model,View,Controller}
            └── Profile/  {Model,View,Controller}
```

**Project uses file-system synchronized groups** — just create files/folders on disk under
`trace/trace/` and they're auto-added to the `trace` target; no `project.pbxproj` edits.

### MVC convention here

- **Controller** = an `@Observable` class holding the screen's logic/state (the "C" of MVC,
  ViewModel role in SwiftUI). The View owns it via `@State private var controller = ...`.
- **View** = SwiftUI views; keep them thin, push logic into the Controller.
- **Model** (per feature) = feature-specific value/presentation types (`RecordMetrics`,
  `StatsSummary`, `GoalProgress`, ...). The **persisted** entities live in `Shared/Models`
  and are shared across features — don't duplicate them per feature.

## Build & run

`xcode-select` points at the Command Line Tools, so CLI builds need `DEVELOPER_DIR` set
to the real Xcode (avoids `sudo xcode-select -s`). Installed sim is iPhone 17 (iOS 26.1).

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Build for simulator (list devices: `xcrun simctl list devices available`)
xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run unit tests (once a test target exists)
xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Prefer building in Xcode for day-to-day work; use `xcodebuild` to verify from the CLI.

## Data model (SwiftData + CloudKit)

CloudKit imposes constraints on the SwiftData schema — **follow these or sync breaks at runtime**:

- Every stored property must be optional **or** have a default value.
- No `@Attribute(.unique)` — CloudKit doesn't support unique constraints.
- Relationships must be optional; always set an inverse.
- Use the CloudKit container matching the bundle ID; configure it in Signing & Capabilities.

Core entities (see `docs/ROADMAP.md` for the full plan):

- `Workout` — type (enum: outdoorRun/indoorRun/cycling/walking), start/end, duration,
  distance, calories, avg/max pace & heart rate, elevation gain, notes
- `RouteSample` — timestamped lat/lon/altitude/speed/heartRate points (relation to Workout)
- `Split` — per-kilometer (or mile) segment: distance, duration, pace
- `Goal` — period (week/month) + target (distance or count)
- `UserProfile` — height, weight, birthdate, sex, unit preference (single row)

## Required capabilities & Info.plist

Done:
- **iCloud → CloudKit** (container `iCloud.net.kolbe.app.trace`) — in `trace.entitlements`
- **HealthKit** (`com.apple.developer.healthkit` = true) — in `trace.entitlements`
- **Background Modes:** `location` + `remote-notification` — in `Info.plist` (`UIBackgroundModes`)
- Usage strings in `Info.plist`: `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSMotionUsageDescription`,
  `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

`LocationManager` requests **when-in-use** auth and sets `allowsBackgroundLocationUpdates`;
that's enough for background GPS while a session is active (blue indicator shows).

The HealthKit entitlement was added by editing `trace.entitlements` directly. Simulator
builds work as-is; for a **device** build, open Xcode → Signing & Capabilities once so
automatic signing registers HealthKit with the App ID.

## Conventions

- Keep views thin; put recording/tracking logic in `Services/` types (`@Observable`).
- One `WorkoutRecorder` owns an in-progress session; it survives backgrounding and
  persists to SwiftData only on finish (buffer samples in memory during the run).
- Use `Measurement<UnitLength>` / `UnitSpeed` and a central formatter for unit display;
  never hardcode "km" vs "mi" — read the user's preference.
- Distances stored in meters, durations in seconds. Convert only at the display layer.
- This is a solo-use app: don't add auth, sharing, or analytics SDKs unless asked.
- 用中文回答问题，保持全程中文，不要中英文混杂。技术术语、代码标识符、API
  名称、命令等本就是英文的可以保留原文，但叙述性的解释一律用中文。
