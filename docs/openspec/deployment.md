# Deployment to Stores

## Prerequisites
- Flutter stable and platform SDKs installed (Android SDK; Xcode and command-line tools on macOS; Visual Studio with C++ workload on Windows).
- Developer accounts: Google Play Console, Apple Developer Program, Microsoft Partner Center.
- Unique package identifiers: Android `applicationId`, iOS/macOS Bundle ID, Windows Identity Name.
- Signing assets: Android keystore, Apple certificates/profiles, Windows code-signing certificate (optional but recommended).
- CI runners: macOS for Apple platforms, Windows for MSIX packaging, Linux/Windows/macOS for Android builds.
 - Publisher name: OldDogSoft LLC (developer/publisher across all stores).

## Versioning & Metadata
- Semantic versioning in `pubspec.yaml` (e.g., `version: 0.1.0+1` where build number increments).
- Store assets: icons, screenshots, short/long descriptions, privacy disclosures, content ratings.
- App permissions kept minimal; declare only what is required.

## Android — Google Play
1. Package name
   - Set `applicationId` in `android/app/build.gradle` and ensure uniqueness (e.g., `com.example.samplecalc`).
2. Keystore and signing
   - Create keystore:
     ```bash
     keytool -genkey -v -keystore samplecalc.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
     ```
   - Configure `android/key.properties` and `build.gradle` for release signing.
3. Build release bundle
   - ```bash
     flutter build appbundle --release
     ```
   - Output: `build/app/outputs/bundle/release/app-release.aab`
4. Upload and rollout
   - Upload AAB to Play Console, complete content rating, privacy policy, and target API requirements.
   - Use internal testing → closed → open testing tracks; then production rollout.

## iOS — Apple App Store
1. Bundle ID and capabilities
   - Create Bundle ID in Apple Developer, enable required capabilities (none expected for a calculator).
2. Certificates and profiles
   - Generate Distribution certificate and App Store provisioning profile.
3. Build and archive
   - Update app metadata (icons, `Info.plist`).
   - Build:
     ```bash
     flutter build ipa --release
     ```
   - Alternatively, archive with Xcode for finer control.
4. Upload and TestFlight
   - Upload via Transporter or Xcode Organizer to App Store Connect.
   - Configure App Privacy, screenshots, and pricing; distribute via TestFlight before App Review.

## macOS — Mac App Store
1. Signing & sandboxing
   - Enable sandboxing and hardened runtime; create appropriate entitlements.
2. Build app
   - ```bash
     flutter build macos --release
     ```
   - Output `.app` bundle in `build/macos/Build/Products/Release/`.
3. Notarization and packaging
   - Sign the app with Developer ID (for Mac App Store, use App Store Distribution certificate).
   - Package to `.pkg` and upload via Transporter.

## Windows — Microsoft Store
1. MSIX packaging
   - Prepare `windows/runner/Resources` (icons) and app identity details.
   - Build:
     ```bash
     flutter build windows --release
     ```
   - Create MSIX package using tooling (e.g., MSIX Packaging Tool or MSIX plugin).
2. Certification and submission
   - Validate with Windows App Certification Kit.
   - Submit via Partner Center; provide metadata and screenshots.

## Other Android Stores
- Huawei AppGallery, Amazon Appstore, Samsung Galaxy Store:
  - Reuse the signed AAB/APK; verify store-specific policies and content rating systems.
  - Adjust metadata and privacy documentation as required.
- F-Droid (optional OSS):
  - Requires open-source licensing and reproducible builds.

## CI/CD Recommendations
- Build matrix:
  - Android AAB: `flutter build appbundle --release`
  - iOS IPA: `flutter build ipa --release` (macOS runner)
  - macOS App: `flutter build macos --release` (macOS runner)
  - Windows MSIX: `flutter build windows --release` + packaging (Windows runner)
- Secrets management:
  - Store keystore files, Apple signing assets, and certificate passwords securely in CI.
- Quality gates:
  - Run `flutter analyze`, engine unit tests, and UI smoke tests before creating artifacts.

## Store Checklist (Per Release)
- Version bump and changelog.
- Icons and screenshots updated for affected platforms.
- Privacy disclosures verified; permissions re-checked.
- Signed artifacts built and validated.
- Submission created; testing tracks configured; rollout strategy defined.
