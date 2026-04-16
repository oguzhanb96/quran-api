# Quality, Release, Monitoring

## Test Pyramid
- Unit tests for calculations, use cases, mapping
- Widget tests for core screens and interactions
- Integration tests for auth, sync, notifications, subscriptions

## Static Checks
- flutter analyze
- dart format --set-exit-if-changed .
- flutter test

## Release Pipeline
- Android AAB release build
- iOS no-codesign validation build in CI
- Flavor based environment variables

## Runtime Monitoring
- Crashlytics for crash reporting
- Firebase Performance traces for startup and screen times
- Event analytics for prayer notification delivery and engagement
