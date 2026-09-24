# Mobile Setup — Flutter

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.x or newer, stable channel)
- Android Studio (for the Android emulator/SDK)
- macOS + Xcode only if you want to build for iOS — **Windows and Linux
  cannot build/run the iOS target at all**, this is an Apple restriction,
  not a Flutter one. Stick to Android on Windows, which is fully supported.
- Run `flutter doctor` and resolve any red ✗ items before continuing

> **Windows-specific:** enable long path support once, in an
> Administrator PowerShell:
> ```powershell
> New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
>   -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
> ```
> Flutter/Android builds generate deeply nested file paths that can exceed
> Windows' default 260-character path limit without this.

## First-time setup

This repo ships only the `lib/` and `test/` source folders — the native
`android/` and `ios/` project folders are intentionally **not** committed
(they're large, platform-specific, and best generated fresh by the Flutter
CLI on each machine). Generate them once:

```bash
cd flutter-app
flutter create --org com.yourteam --project-name stylesync .
```

This fills in `android/` and `ios/` without touching your existing `lib/`
code. Then install dependencies:

```bash
flutter pub get
```

## Run the app

```bash
flutter run
```

Pick an emulator/device when prompted. The shared API client
(`lib/shared/api/api_client.dart`) defaults to
`http://10.0.2.2:5000/api`, which is the Android emulator's alias for your
host machine's `localhost:5000` — change it if you're using iOS simulator
(`http://localhost:5000/api`) or a physical device (your machine's LAN IP).

## Run tests

```bash
flutter test
```

## Analyze / lint

```bash
flutter analyze
```

## Device feature note

This app uses the **camera** (via `image_picker`) for room photo uploads
and **GPS** (via `geolocator`) for locating the nearest service area —
satisfying the assignment's "at least 1 device feature" requirement.
Remember to add camera/location permissions to the generated
`android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`
once you've run `flutter create`.

## Adding your own component's code

Work inside `lib/modules/<your_component>/`. Use the shared `ApiClient`
from `lib/shared/api/api_client.dart` rather than making raw `http` calls
per module.
