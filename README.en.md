> **Language**: [简体中文](README.md) · **English**

<div align="center">

# 🏃 trace

**A running tracker that belongs to you, and only you**

No account · No social feed · No ads · Your data stays yours

</div>

---

## Why trace exists

I'm just an ordinary running enthusiast. Over the years I've switched fitness apps
a few times, and every switch felt like moving house — **the kind where they take
your old keys away**:

- 🗂️ **You can't take your data with you.** Hundreds of kilometers, over a year of
  routes and splits — and when you go looking for an export button, there isn't one.
  Switch apps and everything you've logged is gone, as if you'd never run at all.
- 📣 **Too much social noise.** You open the app to check today's pace, but first you
  scroll past a feed of activity posts, likes, challenges and friend leaderboards.
  I just want to run quietly — I'm not trying to maintain a "fitness social network."
- 📺 **Too many ads.** Splash ads, in-feed ads, membership prompts everywhere — a
  *recording tool* turned into a *content platform*.
- 📡 **It dies offline.** In the mountains, underground, or anywhere with poor signal —
  exactly when you most need it to record — the app keeps spinning, or just fails
  to log at all.

None of these is fatal on its own. Together, they make the simplest thing —
recording a workout — exhausting. What I actually wanted was simple:
**a quiet, reliable logbook whose data is mine.**

So trace happened.

## What trace sets out to fix

trace has exactly one design principle — **a recording tool should get back to
recording**:

| Pain point | trace's answer |
| --- | --- |
| Data locked in, lost on switch | Stored in **your own private iCloud database**, and written back to Apple Health in full — your data is never held hostage |
| Social distraction | **Strictly single-user**: no accounts, feeds, friends, leaderboards, or challenges |
| Ads everywhere | **Zero ads, zero third-party analytics SDKs** — nothing is collected or reported |
| Useless offline | GPS / barometer / pedometer all run **locally** — record with no signal, sync when you're home |

> trace is a personal-use project, open-sourced for anyone bothered by the same things.
> It doesn't try to be everything — just to **do recording well**.

## ✨ Features

**🏃 Recording**
- Four activity types: outdoor run / indoor (treadmill) run / cycling / walking
- Live outdoor GPS tracking, **continues in background and on the lock screen**
- Indoor run distance via CoreMotion pedometer, with manual correction
- Live metrics: duration, distance, current pace (or speed for cycling), heart rate; calories on finish
- Pause / resume / end, with a two-step end confirmation to avoid mis-taps
- Elevation via **barometer** first (far more accurate than GPS altitude), with deadband filtering to kill noise inflation
- **Chinese voice coach**: start / every kilometer (pace + HR) / finish; audible in background and on the lock screen, with an improved voice, ducks your music during announcements and restores it right after

**📖 History**
- Map route playback (MapKit) + summary + splits table
- Per-km pace bar chart + elevation curve (Swift Charts)
- Delete records, edit notes

**📊 Stats**
- Week / month / year summaries: total distance, duration, count, average pace
- Trend charts + personal records: fastest 1 km / 5 K / 10 K, longest distance & duration
- Achievements: cumulative mileage, streak

**🎯 Goals**
- Weekly or monthly distance / count goals with progress gauges

**🔗 Integrations**
- Apple Health: read heart rate & weight, write workouts / routes / energy / distance
- iCloud (CloudKit) private-database sync across devices

**🇨🇳 Mainland China map fix**
- Automatic WGS-84 → GCJ-02 conversion: the China basemap uses GCJ-02
  coordinates while raw GPS is WGS-84; without conversion routes drift by
  hundreds of meters. trace keeps raw WGS-84 in storage and only converts when
  feeding the map (skipped outside China), so routes always hug the road.

## 🗺️ Roadmap

### ✅ Done (v1.0.0)

- Full recording loop for all four activity types (GPS / pedometer / barometric elevation)
- History list, detail, map, charts, splits
- Week / month / year stats, personal records, achievement streaks
- Weekly / monthly goals with progress rings
- Chinese voice coach (improved voice + smart music duck-and-restore)
- HealthKit read/write, iCloud multi-device sync
- Mainland China map coordinate localization

### 🚧 Planned

- Real-device / Apple Watch live heart-rate validation (no HR source on simulator)
- Weather capture (WeatherKit)
- Live Activity / Dynamic Island lock-screen metrics
- Home-screen Widget: weekly distance / latest workout
- Standalone Apple Watch recording app
- Training plans: interval / long-run plans with reminders
- In-run photos pinned to a point on the route
- **Data export (GPX / CSV)** — because "take your data with you" is trace's whole point

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the phased plan and
[`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) for the requirements list.

## 🏛️ Tech architecture

| Layer | Choice |
| --- | --- |
| Language | Swift 5 (Swift 6 concurrency where practical) |
| UI | SwiftUI |
| Persistence | SwiftData + CloudKit sync (private database) |
| Min OS | iOS 18.0+, built with the iOS 26 SDK in Xcode 26.1 |
| Key frameworks | CoreLocation · MapKit · HealthKit · CoreMotion (pedometer / barometer) · Swift Charts · AVFoundation (voice) · ActivityKit · WidgetKit |

**A few project-wide conventions:**

- Keep views thin; recording / tracking logic lives in `@Observable` types under `Services/`.
- `WorkoutRecorder` owns the in-progress session, survives backgrounding, and
  **persists to SwiftData only on finish** (samples buffered in memory during the run).
- Distances are stored in **meters**, durations in **seconds**; km / mi conversion
  happens only at the display layer, reading the user's preference — units are never hardcoded.
- SwiftData schema is constrained by CloudKit: every stored property optional or
  defaulted, no `@Attribute(.unique)`, relationships optional with an inverse —
  break any of these and sync fails at runtime.

## 🧭 Business architecture

Source is organized **business-first**, each business split MVC-style internally:

```
trace/                         # repo root
├── docs/                      # ROADMAP / REQUIREMENTS
└── trace/                     # Xcode project
    ├── Config/                # xcconfig (Team ID lives here, not in pbxproj)
    ├── trace.xcodeproj
    └── trace/                 # app source
        ├── App/               # entry, RootView (5 tabs), OnboardingView
        ├── Shared/            # cross-business layer
        │   ├── Models/        # SwiftData @Model: Workout / RouteSample / Split / Goal / UserProfile
        │   ├── Services/      # LocationManager / HealthKitManager / PedometerManager
        │   │                  #   AltimeterManager / AudioCoach / WorkoutRecorder
        │   ├── Components/    # reusable SwiftUI views (RouteMapView)
        │   └── Common/        # unit preference, map style, formatters, calorie calc
        └── Features/          # one package per business, MVC inside
            ├── Record/   {Model, View, Controller}
            ├── History/  {Model, View, Controller}
            ├── Stats/    {Model, View, Controller}
            ├── Goals/    {Model, View, Controller}
            └── Profile/  {Model, View, Controller}
```

- **Controller** = an `@Observable` class holding the screen's logic/state (the
  SwiftUI ViewModel role); the View owns it via `@State private var controller = ...`.
- **View** = thin SwiftUI views; push logic down into the Controller.
- **Model** (per feature) = feature-local presentation types (`RecordMetrics`,
  `StatsSummary`, `GoalProgress`…); **persisted entities** live in `Shared/Models`
  and are shared across features — never duplicated per feature.

The Xcode project uses **file-system synchronized groups** — drop files into the
folders on disk and they're picked up automatically; no `project.pbxproj` edits.

## 🚀 Build & run

### 1. First-time setup: your Apple Developer Team ID

The repo ships no Team ID. Create your local override:

```bash
cp trace/Config/Local.xcconfig.example trace/Config/Local.xcconfig
# then edit trace/Config/Local.xcconfig and set DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

`Local.xcconfig` is gitignored, so it never leaves your machine. Find your Team ID
at <https://developer.apple.com/account> → Membership, or Xcode → Settings →
Accounts → your Apple ID → Team.

### 2. Bundle ID & CloudKit container (only for running on a real device after forking)

- `PRODUCT_BUNDLE_IDENTIFIER` in `trace/trace.xcodeproj/project.pbxproj`
  (currently `net.kolbe.app.trace`)
- The iCloud container in `trace/trace/trace.entitlements`
  (currently `iCloud.net.kolbe.app.trace`)

Set both to identifiers you own.

### 3. Build

Day to day, open `trace/trace.xcodeproj` in Xcode and hit ⌘R.

From the command line (`xcode-select` usually points at the Command Line Tools, so
set `DEVELOPER_DIR` to the real Xcode):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

The simulator covers most flows, but **heart rate and step-based indoor distance
need a real device** (ideally a paired Apple Watch for HR).

## 📄 License

[MIT](LICENSE) — do what you want.

## 🌟 Get involved

trace is a personal-use project, but if it resonates with you too —

- ⭐ A **Star** is the most direct encouragement
- 🍴 Feel free to **Fork** and make it your own
- 🐛 Found a bug or have an idea? **Issues / PRs** welcome
- 💬 Even a "I've been annoyed by these things too" makes my day

Happy running — and may your data always stay in your own hands. 🏃💨
