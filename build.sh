#!/bin/bash
flutter clean
flutter pub get
dart run build_runner build -d
flutter pub run flutter_launcher_icons
flutter run --release -d cph2491
