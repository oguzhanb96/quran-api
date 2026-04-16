# Quran Companion Technical Blueprint

## Frontend
- Flutter Clean Architecture + MVVM presentation
- Riverpod state orchestration
- Feature-first modular folders
- Offline-first local cache and sync workflow
- Material 3 + RTL + accessibility baseline

## Modules
- Prayer Times
- Quran Reader
- Daily Spiritual Feed
- Dua Library
- Qibla Compass
- Dhikr Counter
- Hijri Calendar
- AI Islamic Assistant
- Subscription and Monetization

## Backend
- Supabase Postgres normalized schema
- Row Level Security on user-owned tables
- Supabase Edge Functions for AI, billing verification, scheduling
- Realtime sync for user data deltas
- Storage buckets for audio and static assets

## Auth
- Supabase Auth with Google and Apple
- Anonymous onboarding and account merge flow
- GDPR export/delete pathway

## Notifications
- Firebase Cloud Messaging topics and direct tokens
- Local scheduling for exact prayer alerts
- Rich notification payload with deep links

## Deployment
- Flutter flavors: dev, staging, prod
- CI pipeline: analyze, test, build, distribute
- Store verification and entitlement sync
