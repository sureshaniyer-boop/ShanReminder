# GitHub + APK build setup

This repository includes a GitHub Actions workflow at:

`.github/workflows/android-apk.yml`

The workflow automatically:

1. Installs Flutter stable.
2. Generates the standard Android Flutter project shell.
3. Applies the ShanReminder V1 source and Android manifest.
4. Runs `flutter pub get` and `flutter analyze`.
5. Builds a release APK.
6. Uploads `app-release.apk` as a GitHub Actions artifact.

## After the repository is uploaded

Go to **Actions → Build Android APK → Run workflow**.

When the run completes, open the workflow run and download the artifact named:

`ShanReminder-V1-Android-APK`

The artifact contains the Android APK for testing.
