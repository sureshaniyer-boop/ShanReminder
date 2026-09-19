# One permanent signing identity for ShanReminder

Status: code prepared; release secrets must be configured before enabling this workflow.

## Why v1.1 could not update to v1.2

Both downloaded APKs have `CN=Android Debug,O=Android,C=US`, but different certificates:

| Build | Certificate SHA-256 |
| --- | --- |
| v1.1 | 19df40f585043d3e2314f4da751994431d3782294cf99576a89826bf2eec945f |
| v1.2 | 22b6ff5eca951344bd322a699ad183005c2deec64eff2cee84a12e2a6497ccd5 |

The original workflow generated a fresh Flutter Android project on each hosted runner and used its temporary debug signing identity. Android requires matching signing identities for normal in-place updates. The APK includes the public certificate, not the private signing key. This patch cannot reconstruct either old private key from an APK.

## Owner setup (one time)

On your own computer, install Python 3.9+, Java (keytool), and GitHub CLI. Authenticate `gh auth login` to the account that administers this repository. Check out this signing-fix branch. Do not send the password or private keystore through chat or commit them to GitHub.

For a new permanent identity, run this from the checkout in PowerShell:

```powershell
python tools/setup_signing.py --create --keystore "$env:USERPROFILE\ShanReminder-private\release.p12"
```

Choose a strong password when prompted. The helper creates a PKCS12 keystore outside the repository, asks you to back up the file/password, and then uploads three encrypted GitHub repository secrets:

- ANDROID_SIGNING_KEYSTORE_BASE64
- ANDROID_SIGNING_PASSWORD
- ANDROID_SIGNING_ALIAS

It also pins the public certificate in the ANDROID_SIGNING_CERT_SHA256 repository variable. This fingerprint is public information. On any retry, reuse the original file by omitting `--create`. The helper refuses to replace an existing identity with a different certificate. If credentials already exist from another setup, review that setup before proceeding.

Keep independent secure backups of the keystore and password; GitHub Secrets cannot be downloaded as a recovery copy. Store/key passwords must match for this PKCS12 workflow. Base64 is encoding, not encryption; its protection comes from GitHub Secrets.

## Enable the fixed release workflow

After successful setup, merge this change to main. The workflow will verify the keystore fingerprint, explicitly sign with the release identity, use an increasing build number (100 + the run number), cryptographically verify the APK and its certificate, and upload the APK only on success. There is no fallback to debug signing. Keep this workflow's run-number sequence; if replacing it, choose a build number higher than every previously distributed release.

The original installed v1.2 is signed with a different temporary key. A new permanent key does not make it update-compatible. Do not uninstall again without preserving any reminders first. The current app has no export/import feature; record existing tasks manually before a one-time migration, or add a migration/backup feature through a build signed with the old key if that key is recovered. Once using the permanent key, later APKs signed with that same key and a higher version code can update normally.

## Google Play Protect is separate

The screenshot says Google has not seen an app from this developer before. It does not by itself prove malware or state that Google Play publication is mandatory. A permanent certificate is necessary for stable updates but is not a Google safety approval and cannot guarantee warnings disappear.

Use Google's documented scan/review process and consider Play Console testing/distribution with Play App Signing. Publishing requires the owner's developer-account setup and applicable review steps; this patch does not publish or verify the app with Google. For continuity across Play and direct APK distribution, plan the app signing key before enrollment; an upload key and a Play app signing key can differ.

Do not disable Play Protect as the fix. If a warning persists in error after review, follow Google's Play Protect guidance for the applicable warning and appeal route.

- https://developer.android.com/studio/publish/app-signing
- https://developers.google.com/android/play-protect/warning-dev-guidance
- https://support.google.com/googleplay/answer/2812853

## Validation

Run `python -m unittest discover -s tests -v` to check signing configuration and fail-closed certificate handling. Real release APK verification still requires owner-provided signing secrets and a successful GitHub Actions release build.
