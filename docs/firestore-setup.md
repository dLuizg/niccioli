# Firestore and Firebase Setup

This project uses Firebase client configuration files that are generated locally
and intentionally ignored by Git:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Generate these files after cloning the repository or after Firebase API keys are
rotated.

## Prerequisites

1. Install Flutter and run:

   ```powershell
   flutter pub get
   ```

2. Install the Firebase CLI and FlutterFire CLI:

   ```powershell
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

3. Log in with an account that has access to the Firebase project:

   ```powershell
   firebase login
   ```

## Generate Firebase Config

Run this from the repository root:

```powershell
flutterfire configure --project=niccioli-enersys --platforms=android,ios --android-package-name=com.niccioli.app --ios-bundle-id=com.example.niccioli --android-out=android/app/google-services.json --ios-out=ios/Runner/GoogleService-Info.plist --overwrite-firebase-options --yes
```

If the iOS plist is not created by FlutterFire, generate it with Firebase CLI:

```powershell
firebase apps:sdkconfig IOS 1:785121927334:ios:3a086a1210df9fb8025467 --out ios\Runner\GoogleService-Info.plist
```

## Verify

The files should exist locally:

```powershell
Test-Path lib\firebase_options.dart
Test-Path android\app\google-services.json
Test-Path ios\Runner\GoogleService-Info.plist
```

They should remain ignored by Git:

```powershell
git status --short --ignored
```

Build or analyze the project:

```powershell
flutter analyze
flutter build apk --debug
```

## Security Notes

- Do not commit generated Firebase config files.
- If GitHub reports a leaked Google API key, delete or rotate it in Google Cloud
  Console before closing the alert.
- Restrict replacement keys in Google Cloud:
  - Android: package `com.niccioli.app` plus debug/release SHA-1 certificates.
  - iOS: bundle id `com.example.niccioli`.
