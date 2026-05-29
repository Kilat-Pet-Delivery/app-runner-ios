/*
 APNs payload contract assumed by the Kilat Runner inbox and future push
 surfaces.

 Required aps fields:
 - alert.title: localized notification title shown in the system banner.
 - alert.body: concise delivery, payout, or account event body.
 - sound: "default" for normal events, "kilat_job.caf" for urgent job offers.
 - badge: unread notification count for the runner.
 - category: one of JOB_OFFER, DELIVERY_UPDATE, PAYOUT_UPDATE, ACCOUNT_NOTICE.

 Custom payload fields:
 - notificationId: UUID matching the notification returned by GET /notifications.
 - type: booking, tracking, payment, payout, account, or system.
 - deepLink: kilatrunner:// path for future direct navigation.
 - createdAt: ISO-8601 timestamp.

 Category actions:
 - JOB_OFFER_ACCEPT opens the job detail and accepts only after in-app confirm.
 - JOB_OFFER_DECLINE opens DeclineReasonSheet; no background decline mutation.
 - PAYOUT_VIEW opens the earnings tab or cash-out detail when that endpoint ships.
 */
