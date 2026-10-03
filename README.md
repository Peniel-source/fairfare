# FairFare

FairFare helps moto-taxi riders in Kigali know a fair price before they get on a bike. Riders look up a corridor (e.g. Kacyiru → Kimironko), see a price range and median, negotiate with confidence, then report what they paid. Reports are verified by other riders, and aggregated price data is notarized on the Cardano testnet so it can't be quietly altered.

FairFare does not set prices, dispatch drivers, or take commission.

## Repository layout

```
fairfare/
├─ app/        # Flutter mobile app
├─ backend/    # NestJS API 
├─ docs/       # Concept note, engine logic spec, Flutter roadmap
└─ .github/    # PR template, CI workflows
```

Start with the documents in `docs/`. The Flutter roadmap is the source of truth for stack, theme, and folder structure.

## Running the app

Requirements: Flutter (stable channel), Android Studio or Xcode, a device or emulator.

```bash
git clone https://github.com/Peniel-source/fairfare.git
cd fairfare/app
flutter pub get
flutter run
```

Check your setup with `flutter doctor`.

## Branch workflow

| Branch | Purpose |
|---|---|
| `main` | Production. Always stable and demo-ready. Updated only by merging `dev`. |
| `dev` | Integration branch. All feature work lands here via pull request. |
| `feature/*`, `fix/*` | Short-lived working branches, created from `dev`. |

Nobody pushes directly to `main` or `dev`. Every change goes through a pull request with review. See [CONTRIBUTING.md](CONTRIBUTING.md) for the details.

## Team

1. Eelaf — role
2. Menes — role
3. Toky  — role
4. Benjamin — role
5. Peniel — role