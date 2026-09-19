# ShanReminder V1

A local-first Flutter reminder app designed around the approved premium **Gold + Maroon / Royal Blue / Cream / Emerald** concept.

## V1 features

- Add task/event title and optional description
- Choose date and time
- Reminder choices: at time, 10 min, 30 min, 1 hour before
- Repeat: none, daily, weekly, monthly
- Priority: High / Medium / Low
- Categories: Work, Personal, Astrology, Family, Health, Other
- Today dashboard: task, completed, pending and overdue counts
- Upcoming task view
- Complete and delete tasks
- Local device persistence
- Local notification scheduling
- Four selectable premium themes while preserving a gold accent

## Quick start

This package contains the complete app source layer and Android reminder manifest configuration. Platform boilerplate should be generated using your installed Flutter SDK.

1. Install current Flutter stable (Dart 3.10+).
2. In a terminal, create the base app:

   ```bash
   flutter create --org com.shanreminder shan_reminder
   ```

3. Replace the generated `pubspec.yaml` and `lib/` folder with the ones in this package.
4. Merge/replace `android/app/src/main/AndroidManifest.xml` with the included manifest.
5. Run:

   ```bash
   flutter pub get
   flutter run
   ```

6. On Android, allow **Notifications** and **Alarms & reminders / exact alarms** when prompted.

## Build Android APK

```bash
flutter build apk --release
```

Output is normally at:

`build/app/outputs/flutter-apk/app-release.apk`

## iPhone

From macOS with Xcode installed:

```bash
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode to sign and install on an iPhone.

## Important V1 note

The current execution environment used to prepare this source does not include the Flutter SDK, so the project source could not be compiled here. Package versions were aligned with current pub.dev releases as of September 2026. The notification package requires Android notification permission and exact-alarm configuration for reliable exact-time reminders.

## V2 ideas

- Snooze action buttons directly from the notification
- Google Calendar sync
- Cloud backup/login
- Voice task entry
- Daily morning summary
- Persistent reminders until completed
- Widgets
- AI task prioritisation

## GitHub Actions APK build

A ready-to-use workflow is included at `.github/workflows/android-apk.yml`.
After uploading this project to GitHub, open **Actions → Build Android APK → Run workflow**. When the run succeeds, download the `ShanReminder-V1-Android-APK` artifact.
