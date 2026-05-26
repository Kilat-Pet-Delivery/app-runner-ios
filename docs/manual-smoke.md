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

## Plan B End-to-End Walk

Run this after the baseline MVP checklist above. The camera, signature, APNs, and background-location steps must be verified on a real iPhone.

- [ ] Sign up a new runner and complete the Apply form.
- [ ] Confirm Permissions appears after authentication; grant Location, Camera, and Notifications.
- [ ] Confirm Dashboard coach marks appear once, then dismiss and relaunch to verify they stay dismissed.
- [ ] Go online, accept a live-pet booking, and verify Start route opens the Pre-trip Checklist before Active Delivery.
- [ ] Complete pickup, drop-off arrival, photo proof, signature proof, recipient name, and customer rating.
- [ ] Open Chat during delivery, exchange messages with the paired customer, and verify presence/read receipt indicators.
- [ ] Trigger the offline drill below during Active Delivery, then reconnect and verify queued waypoint count clears.
- [ ] Long-press SOS, cancel during cooldown, and verify the incident records as a false alarm.
- [ ] From Earnings, open Cash Out, Bank Accounts, add an account, set it as default, then complete a cash-out request.
- [ ] Open Quests, complete a daily quest, redeem it, and verify the completion state.
- [ ] Open Hot Zones and verify polygons, multiplier labels, and the surge-focused deep link case.
- [ ] Open Performance, Reviews, and Refer a Friend; verify loaded data and share sheet launch.
- [ ] Force a `tip_received` push, verify Tip Received opens, tap Send thank you, and confirm Chat opens with a quick reply.
- [ ] Sign out and sign back in; verify permissions do not re-prompt and coach marks do not reappear.

## New Screen Trigger Matrix

| Screen or runtime surface | How to trigger | Expected state |
| --- | --- | --- |
| Apply form | Login screen -> Apply | Required fields validate, consent gates submit. |
| Application received | Submit Apply form | Confirmation shows application ID and Done returns to Login. |
| Forgot password | Login -> Forgot password | Email field submits reset request. |
| Reset sent | Submit forgot-password email | Envelope state shows resend and open-mail actions. |
| Permissions onboarding | First authenticated launch with undetermined permissions | Location, Camera, Notifications steps resolve or show settings guidance. |
| Coach marks overlay | First Dashboard visit after login | Online toggle and notification affordance are highlighted once. |
| No jobs nearby | Available Jobs with empty API response | Empty state offers hot zones, radius, and job alert CTAs. |
| Offline banner | Disable network while on Dashboard, Jobs, or Active Delivery | Red banner appears within two seconds and opens Offline state when tapped. |
| Offline full-screen state | Tap Offline banner | Queued waypoint count appears while delivery updates are buffered. |
| Job detail | Tap a row in Available Jobs | Fare, pickup/drop-off, pet details, and accept/decline actions render. |
| Decline reason sheet | Job detail -> Decline | Reason selection is required before submit. |
| Job accepted | Accept a job | Confirmation appears with Start route CTA. |
| Pre-trip checklist | Start route for a live-pet booking | All five checks are required before continuing. |
| Active delivery | Start route after accepted job | Map, next action, waypoint upload, and incident affordances render. |
| Arrived at pickup | Tap arrive/pickup action | Pickup confirmation state appears before pickup completion. |
| Proof of delivery | Arrive at drop-off | Photo, signature, recipient, and submit proof controls render. |
| Delivery complete | Submit valid proof | Success state appears and can route to rating/earnings. |
| Cancel active delivery sheet | Active Delivery -> Cancel/report flow | Cancellation reason and guarded submit state render. |
| Report problem | Support/incident entry point | Optional photo and problem type submit correctly. |
| SOS | Active Delivery red alert | One-second hold starts cooldown and cancel window. |
| Chat thread | Support, delivery chat, or `chat_message` push | Messages load, quick replies send, presence/read receipts update. |
| Support | Dashboard support entry | Hero chat action opens support thread. |
| Notifications inbox | Bell icon or notifications route | Notifications are grouped by date and tap routes through deep-link handler. |
| Job history | Dashboard/history route | Completed/cancelled job rows load. |
| Scheduled jobs | Dashboard/scheduled route | Jobs are grouped by day bucket. |
| Vet pickup detail | Tap a vet booking | Vet-specific pickup instructions render. |
| Pet profile | Job detail pet profile link | Pet traits, handling notes, and owner notes render. |
| Earnings | Dashboard earnings tab | Balance and completed job payouts render. |
| Cash out | Earnings -> Cash Out | Amount entry, bank destination, and confirmation flow render. |
| Cash out sent | Complete cash out | Success state shows transfer copy and Done action. |
| Bank accounts | Cash Out -> Change | Saved accounts, default pill, add slot, and delete/default actions render. |
| Add bank account sheet | Bank Accounts -> Add | Bank picker, account number, holder fields, and submit validation render. |
| Quests | Dashboard or `quest_completed` push | Daily and weekly quests group correctly, redeem state persists. |
| Tip received sheet | `tip_received` push | Tip amount and thank-you action render. |
| Hot zones | Dashboard or `surge_active` push | Map polygons and multiplier labels render. |
| Performance | Dashboard or tier sheet | Tier, metrics, and trend modules render. |
| Reviews | Dashboard reviews route | Star filter refines review feed locally. |
| Refer a friend | Dashboard referral route | Referral code is shareable and payout status appears. |
| Profile | Dashboard profile route | Identity and runner profile summary render. |
| Settings | Dashboard settings route | Theme, language, and notification category preferences render. |
| Push deep-link runtime | Tap supported APNs payload | Router consumes the intent once and lands on the mapped screen. |

## Push Deep-Link Cases

Use APNs sandbox, Xcode notification simulation, or the backend push test endpoint if available. For cold-launch tests, terminate the app first, deliver the payload, and tap the notification.

| Category | Required payload fields | Expected destination |
| --- | --- | --- |
| `chat_message` | `thread_id` | Chat thread for that thread ID. |
| `tip_received` | tip payload fields used by `TipReceivedPayload` | Tip Received sheet. |
| `sos_ack` | `incident_id` | Notifications/incident acknowledgement route. |
| `incident_assigned` | `incident_id` | No visible runner route; app stays stable. |
| `quest_completed` | `quest_id` | Quests. |
| `tier_promoted` | `tier` | Tier promotion sheet with Performance action. |
| `surge_active` | `zone_code` | Hot Zones. |
| `proof_required` | `booking_id` | Active Delivery proof route for that booking. |

Record one foreground and one cold-launch result per category:

| Category | Foreground result | Cold-launch result | Notes |
| --- | --- | --- | --- |
| `chat_message` | Not run | Not run | |
| `tip_received` | Not run | Not run | |
| `sos_ack` | Not run | Not run | |
| `incident_assigned` | Not run | Not run | |
| `quest_completed` | Not run | Not run | |
| `tier_promoted` | Not run | Not run | |
| `surge_active` | Not run | Not run | |
| `proof_required` | Not run | Not run | |

## Offline Simulator Drill

Use this drill for quick simulator regression before the real-device pass.

1. Launch on simulator and log in.
2. Open Dashboard, Available Jobs, or Active Delivery.
3. Toggle the Mac network off or use a network link conditioner profile.
4. Confirm the offline banner appears within two seconds.
5. Tap the banner and confirm Offline state opens.
6. While in Active Delivery, confirm buffered waypoint count is shown.
7. Restore network and confirm banner disappears and queued action state clears after upload.

## Result Log

Date:
Device:
iOS version:
Backend commit(s):
App commit:
Smoke scope: Baseline MVP + Plan B end-to-end + push deep links + offline drill

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
