# KilatRunner iOS

Native SwiftUI runner app for the Kilat Pet Delivery runner MVP.

## Requirements

- Xcode 15 or newer
- iOS 17 simulator or device
- Local backend via `../infrastructure`

## Local Backend

```sh
cd ../infrastructure
make up
make seed
```

Test runner credentials:

- Email: `runner.test@kilat.my`
- Password: `TestRunner123!`

## References

- Spec: `../docs/superpowers/specs/2026-05-15-app-runner-native-mvp-design.md`
- Plan: `../docs/superpowers/plans/2026-05-15-app-runner-ios-mvp-plan.md`
