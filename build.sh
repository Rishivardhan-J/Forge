#!/bin/bash
flutter pub get < /dev/null
dart run build_runner build -d < /dev/null
flutter run -d cph2491 < /dev/null
