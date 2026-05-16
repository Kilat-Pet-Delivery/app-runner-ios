# KilatRunner iOS

Native SwiftUI runner app for the Kilat Pet Delivery MVP.

**MVP status:** feature-complete for the iOS happy path. Manual real-device smoke is documented in `docs/manual-smoke.md`.

## Screens

- Login with seeded runner credentials
- Dashboard with online/offline status
- Available jobs list
- Job detail and accept flow
- Active delivery map with GPS, waypoint upload, WebSocket tracking, pickup, and delivered actions
- Earnings list from completed runner bookings

## Architecture

The app follows a small layered SwiftUI architecture:

```text
View -> @Observable ViewModel -> Repository -> URLSession / WebSocket / CLLocationManager -> Keychain
```

Manual constructor injection keeps the MVP easy to inspect. `AppSession` is the only shared observable app state.

Primary references:

- Spec: `../docs/superpowers/specs/2026-05-15-app-runner-native-mvp-design.md`
- Plan: `../docs/superpowers/plans/2026-05-15-app-runner-ios-mvp-plan.md`
- Smoke checklist: `docs/manual-smoke.md`

## Requirements

- Xcode 15 or newer
- iOS 17 simulator or physical iPhone
- Local backend via `../infrastructure`

## Local Backend

```sh
cd ../infrastructure
make up
make seed
```

Seed runner credentials:

- Email: `runner.test@kilat.my`
- Password: `TestRunner123!`

## Running Locally

Open `KilatRunner.xcodeproj` in Xcode, select the `KilatRunner` scheme, then run on a simulator or device.

For a physical iPhone, update `KilatRunner/App/AppEnvironment.swift` so the Debug `baseURL` points to a backend host reachable from the phone. `localhost` only works for simulator-based testing.

## Manual Smoke

Use `docs/manual-smoke.md` for the real-device pass. The smoke covers login, online status, accepting a booking, active delivery GPS, WebSocket reconnect, pickup/delivered transitions, earnings, and a 10-minute background session.

## Notes

- The current Debug login path may contain a temporary stub for local previewing without a backend. Remove it before declaring a production-ready build.
- UI tests are intentionally out of MVP scope; repository, networking, storage, buffer, and view-model coverage are handled with XCTest.
