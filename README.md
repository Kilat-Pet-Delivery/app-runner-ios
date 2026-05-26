# KilatRunner iOS

Native SwiftUI runner app for the Kilat Pet Delivery MVP.

**MVP status:** Plan B feature-complete for the runner iOS happy path and 42 screen/runtime surfaces. Manual real-device smoke is documented in `docs/manual-smoke.md`.

## Screens

### Auth + Onboarding

- Login with seeded runner credentials
- Apply form
- Application received confirmation
- Forgot password
- Reset sent confirmation
- Permissions onboarding
- Dashboard coach marks overlay

### Core Delivery

- Dashboard with online/offline status
- Available jobs list with no-jobs-nearby state
- Job detail
- Decline reason sheet
- Job accepted confirmation
- Live-pet pre-trip checklist
- Active delivery map with GPS, waypoint upload, WebSocket tracking, pickup, and delivered actions
- Arrived at pickup confirmation
- Proof of delivery
- Delivery complete
- Cancel active delivery sheet
- Report problem
- SOS

### Work Queue + Support

- Job history
- Scheduled jobs
- Vet pickup detail
- Pet profile
- Chat thread
- Support
- Notifications inbox
- Push notification runtime with cold-launch deep-link routing

### Earnings + Account

- Earnings list from completed runner bookings
- Cash out
- Cash out sent
- Bank accounts
- Add bank account sheet
- Profile
- Settings

### Loyalty + Operations

- Quests
- Tip received sheet
- Hot zones
- Performance
- Reviews
- Refer a friend
- Offline banner
- Offline full-screen state

## Architecture

The app follows a small layered SwiftUI architecture:

```text
View -> @Observable ViewModel -> Repository -> URLSession / WebSocket / CLLocationManager -> Keychain
```

Manual constructor injection keeps the MVP easy to inspect. `AppSession` is the only shared observable app state.

Primary references:

- Spec: `../docs/superpowers/specs/2026-05-15-app-runner-native-mvp-design.md`
- Plan: `../docs/superpowers/plans/2026-05-15-app-runner-ios-mvp-plan.md`
- Plan B screens: `../docs/superpowers/plans/2026-05-19-app-runner-ios-screens-plan.md`
- Smoke checklist: `docs/manual-smoke.md`

## Requirements

- Xcode 15 or newer
- iOS 17 simulator or physical iPhone
- Local backend via `../infrastructure`
- Swift Package Manager dependency: `lib-ui-ios` pinned at `0.3.0` in `KilatRunner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

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
