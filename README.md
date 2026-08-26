# Forge

Forge is a privacy-first, offline-only habit tracking application built with Flutter.

## Core Features
- **Habit Tracking:** Track daily habits using the Transit Map visualization and Evidence Logs.
- **Insights:** Monitor your consistency and detect friction points preventing you from completing habits.
- **Geofencing & Context-Aware Notifications:** Set notifications that trigger based on location or habit stacking.
- **Data Export & Backup:** Export your history to CSV or PDF, and backup/restore via JSON.

## Product Boundaries & Architecture
**Important Note:** The original specification evaluated "accountability pairing" (multi-user sharing of habit statuses). This has been **permanently excluded** as an intentional product decision. 

Every phase of Forge has been built on one core architectural commitment: **zero network dependency, on-device-only data, privacy-first by construction.** Sharing habit state between users requires a backend server or peer-to-peer networking, which breaks this commitment.

Forge is a **single-user, offline-first product by design, for this version and for every version reasonably expected after it**. Multi-user features are not on the product roadmap.

## Building the App
```bash
flutter pub get
dart run build_runner build -d
flutter run --release
```
