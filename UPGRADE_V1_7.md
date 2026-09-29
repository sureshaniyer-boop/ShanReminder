# ShanReminder 1.7 upgrade

Implemented:
- Horizontal slide navigation: Home → Calendar → Tasks → Settings; reverse swipe goes back.
- Theme-coloured circular expand/collapse controls for Today, Tomorrow, Next Week, Next Month, Next Year.
- Actual calendar periods, with visible date ranges. Next Week is the next Monday–Sunday. A task may appear in multiple matching period views (for example Tomorrow and Next Month on a month boundary). Other Dates retains tasks outside those windows.
- Calendar date grid, selected-date task list, and add task on selected day. Calendar and task groups share the same task store.
- JSON backup export, Gmail/Drive sharing through Android's share sheet, and validated restore with preview. Restore adds missing IDs; current tasks win on conflicts. Reminders are rescheduled after restoring.
- Google Drive appDataFolder snapshots and selection of the latest 100 snapshots for restore. Existing snapshots are not overwritten or deleted.
- Opt-in automatic backups while the app is running and the Google account is connected; reconnect after app restart. This is not an Android background backup worker.

## Google account setup

Cloud backup needs a Google Cloud project with Drive API enabled, an OAuth consent configuration, an Android OAuth client matching `com.shanreminder.shan_reminder` and the **actual signing SHA-1**, and a Web OAuth client from the same project. If the consent app is in testing, add the intended Google account as a test user. Only the `drive.appdata` scope is requested; the app does not read Gmail or other Drive documents.

Set GitHub repository variable `GOOGLE_WEB_CLIENT_ID` to the Web client ID. It is a public OAuth identifier, not a client secret. No client secret belongs in the APK. The build passes it using `--dart-define`. Without this configuration, cloud controls explicitly say unavailable; file export, Gmail share, and file restore remain available.

Sources: https://pub.dev/packages/google_sign_in_android and https://developers.google.com/workspace/drive/api/guides/appdata

## Release signing blocker

The current main workflow generates a fresh Android project and uses its debug signing configuration for `flutter build apk --release`. The TEST artifact is not certified as an in-place update. Do not uninstall a data-bearing installation to install it.

A production build must use the existing release keystore or the previously prepared permanent signing setup, then compare its certificate with the installed APK. Never commit a keystore or passwords. Existing repository history includes the permanent-signing branch; it must be reconciled before a production release. No claim of in-place compatibility is made by this branch.

## Validation

Passed locally: 12 dependency-free Dart checks covering task/notification-field backup round trip, merge conflict preservation, malformed and duplicate input rejection, leap days, Monday boundaries, and month/year rollover. Dart formatting parsed all changed source files, and `git diff --check` passed.

The workflow is configured for Flutter analyzer, backup/date-window/navigation widget tests, and layout previews. These full checks have not run yet: local dependency resolution is incomplete, and automatic approval review blocked the GitHub push pending explicit publication permission. No APK has been built for this upgrade.

Device verification remains necessary for Gmail sharing, Android document picker, Google OAuth, notification delivery, and in-place installation/data retention.
