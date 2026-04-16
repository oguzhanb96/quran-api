# Play Console Release Checklist

## Build Identity
- App name: Quran Companion
- Application ID: app.misbah.companion
- Version name: 1.0.1
- Version code: 2

## Signed Artifacts
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB SHA256: `34f7fee63b4f3debc479d1c630f01ac79aa4a224fc57a2bd5acb477f7f6f6ecb`
- APK SHA256: `4715f0512222666ff1a47801b1e3fbc4f90f5b51b4aac1e706d95a01e5608b43`

## Upload Key Certificate
- Alias: `misbah`
- SHA1: `20:80:16:CF:5C:45:18:BD:BF:F6:54:8A:EE:D8:C5:11:B2:96:18:38`
- SHA256: `4A:2C:9D:DF:B2:BF:EF:F6:AB:8D:51:6A:08:D3:81:A2:A6:DD:32:76:F1:D3:C4:2F:B2:25:FD:8C:BA:07:30:A8`
- Keystore: `android/upload-keystore.jks`
- Properties file: `android/key.properties`

## Completed
- [x] Release keystore generated
- [x] `android/key.properties` created
- [x] Signed release AAB built
- [x] Signed release APK built
- [x] APK signature verified with `apksigner`
- [x] Analyzer clean (`flutter analyze`)

## Manual Play Console Steps
- [ ] Play Console -> Setup -> App integrity -> Register upload certificate (if first upload)
- [ ] Production release -> Create new release -> Upload `app-release.aab`
- [ ] Fill release notes (TR/EN)
- [ ] Data safety form review
- [ ] App content forms review (ads, target audience, news/status)
- [ ] Store listing screenshots/icon/feature graphic check
- [ ] Privacy policy URL validation
- [ ] Country/region availability review
- [ ] Rollout percentage choose (5%-20% staged recommended)
- [ ] Monitor Android vitals and crashes after rollout

## Security Notes
- Never commit `android/key.properties`
- Never commit `android/upload-keystore.jks`
- Keep keystore backup in a secure offline location
