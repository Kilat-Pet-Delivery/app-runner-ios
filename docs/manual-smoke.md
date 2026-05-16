# KilatRunner iOS Manual Smoke Checklist

Use this checklist for the real-device MVP smoke. Run it on a physical iPhone with the local backend stack running.

## Setup

- Backend: from `../infrastructure`, run `make up` then `make seed`.
- Runner account: `runner.test@kilat.my` / `TestRunner123!`.
- Owner account: use the seeded owner account from the backend seed data or Bruno environment.
- Device: iPhone on the same network as the backend host.
- Xcode scheme: `KilatRunner`, Debug configuration.
- API base URL: confirm `KilatRunner/App/AppEnvironment.swift` points to the reachable backend host for device testing.
- Backend logs to watch:
  - `service-booking` for booking state transitions.
  - `service-runner` for `/runners/me/location`.
  - `service-tracking` or gateway logs for WebSocket connection and reconnect events.

## Seed A Fresh Booking

Create a booking as the owner via Bruno or curl before starting the runner flow.

Expected booking path:

1. `POST /api/v1/bookings` creates a requested booking.
2. Runner accepts it from the app.
3. Pickup moves it to delivery in progress.
4. Delivered moves it to the backend delivered or awaiting-confirmation state, depending on current service behavior.

Record the booking ID here:

- Booking ID:
- Booking number:

## Checklist

- [ ] Login works on real iPhone with the seeded runner account.
- [ ] Toggle online and confirm real available jobs appear from `service-booking`.
- [ ] Accept the freshly created booking from the Available Jobs flow.
- [ ] Active Delivery map shows runner location plus pickup and drop-off pins.
- [ ] Walk with the phone locked or in pocket; backend `/runners/me/location` receives waypoint batches.
- [ ] WebSocket connection is visible in backend logs, and the app recovers after a forced disconnect.
- [ ] Tap Picked Up; backend booking state advances to `delivery_in_progress` or `in_progress`.
- [ ] Tap Mark Delivered; backend booking state advances to delivered or awaiting confirmation.
- [ ] Earnings screen lists the completed booking with payout amount.
- [ ] App survives a 10-minute background session without crashing or losing GPS updates.

## Result Log

Date:
Device:
iOS version:
Backend commit(s):
App commit:

| Item | Result | Notes |
| --- | --- | --- |
| 1. Login | Not run | |
| 2. Online + jobs | Not run | |
| 3. Accept job | Not run | |
| 4. Active delivery map | Not run | |
| 5. Background waypoint upload | Not run | |
| 6. WebSocket reconnect | Not run | |
| 7. Pickup transition | Not run | |
| 8. Delivered transition | Not run | |
| 9. Earnings | Not run | |
| 10. 10-minute background | Not run | |

## Phase 10 Bug Backlog

- None yet.
