# Release & Packaging

## Publisher
- OldDogSoft LLC is the developer and publisher across all stores.

## Windows (Microsoft Store)
- MSIX package, app manifest, capabilities.
- Validate with Windows App Certification Kit.

## Android (Google Play)
- Android App Bundle (AAB), target latest API level.
- Sign with Play App Signing; privacy policy compliance.

## iOS (Apple App Store)
- Build on macOS; code signing; App Store Connect.
- TestFlight for beta; App Privacy details.

## macOS (Mac App Store)
- Notarization, sandboxing, hardened runtime.
- App bundle signing; upload via Transporter/Xcode.

## CI/CD
- macOS runner for Apple platforms; Windows runner for MSIX.
- Secrets for signing stored securely; automated analyze/test steps.
