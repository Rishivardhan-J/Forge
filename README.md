# Forge

Most habit trackers measure the wrong thing. They measure outcomes—streaks, perfect months, unbroken chains—because outcomes are easy to count. But behavior isn't changed by outcomes. It's changed by systems.

Forge is a habit-formation app built on the framework described in *Atomic Habits*. It doesn't care about your streak. It cares about your system.



---

## The Philosophy of the App

Forge is built around a few core beliefs that manifest directly in the UI and architecture. If you're looking at the codebase, understanding these decisions will explain why things are built the way they are.

### 1. Habit Stacking as a Transit Map
You don't build a new habit in a vacuum. You attach it to something you already do. Forge treats these sequences as **Habit Stacks**, visualizing them as a transit map. One habit leads directly to the next, building momentum through environmental cues rather than raw willpower.

![Transit Map Placeholder](assets/readme/transit-map.gif)
*(Note: Replace with a 3-second looping GIF of the transit map line animating on the Today screen.)*

### 2. Consistency Over Streaks
A single missed day shouldn't zero out a year of work. The traditional "streak" model punishes human moments and encourages abandonment once the chain breaks. Forge uses a **Rolling Consistency Score** that decays mathematically. Missing a day causes a dip. Missing a week causes a drop. But you never artificially reset to zero. The system accommodates reality.

### 3. The Two-Minute Escape Valve
Every habit in Forge can have a "Two-Minute Version." When life happens and you can't do the full habit, you can log the two-minute version. It counts as a success. This prevents the all-or-nothing thinking that kills most habit changes and keeps the system intact even on bad days.

### 4. Objective Colors, Not Judgemental Ones
Forge deliberately avoids red for failure. Missed habits aren't errors; they are simply unlit or muted. 
- **Teal**: Completed (System working)
- **Amber**: Excused / Two-Minute Version (System adapted)
- **Muted Gray**: Pending / Missed (System data point)

## The Architecture

Forge is a local-first application. There are no remote servers logging your behavior, no mandatory accounts, and no loading spinners.

- **Framework**: Flutter (Material 3 with bespoke styling)
- **State Management**: Riverpod
- **Database**: Isar — chosen for synchronous reads, full-text search, and seamless cross-isolate support.
- **Background Automation**: Geofencing and location-based triggers.
- **Native Integrations**: iOS and Android home screen widgets for glanceable system tracking.

## Current State of the Build

Forge is currently in a stable `v1.0` state. The original six-phase build plan is complete:

- [x] **Core System**: Isar database, Riverpod state, and the core Habit entity.
- [x] **Transit Map UI**: Custom painter implementations for the habit stacking visualization.
- [x] **The Two-Minute Rule**: Logic and UI for partial completions.
- [x] **Environment Design**: Geofencing and location-based context switching.
- [x] **Analytics**: The rolling consistency score algorithm and historical insights chart.
- [x] **Data Ownership**: PDF/CSV exports and full JSON backup/restore functionality.

## Getting Started

Because Forge is local-first, setting it up for development is entirely standard. There are no external Firebase configs or API keys to inject.

```bash
# 1. Clone the repository
git clone https://github.com/Rishivardhan-J/Forge.git
cd Forge

# 2. Get dependencies
flutter pub get

# 3. Generate Isar models and Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

## Contributing

When contributing to Forge, keep the system philosophy in mind. Features that add friction, guilt, or focus purely on outcomes will be rejected. Features that reduce friction, automate environments, and focus on the process are welcome.
