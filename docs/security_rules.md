# Firestore security rules — B2

The rules follow the ownership table in [erd.md](erd.md). Access not explicitly allowed is denied. Backend Admin SDK operations bypass these client rules.

| Collection | Client reads | Client writes |
|---|---|---|
| `passengers` | Own profile only | Create own basic profile; change display name only |
| `passengers/{uid}/savedRoutes` | Owner only | Owner CRUD; creation timestamp is immutable |
| `corridors` | Public | None |
| `corridorStats` | Public | None |
| `notarizations` | Public | None |
| `leaderboard` | Public | None; backend copies public name/score |
| `reports` | Owner only | Create pending; edit price or delete while pending |
| `wallets` | Owner only | None |
| `walletEntries` | Owner only | None |
| `cashOutRequests` | Owner only | Create own pending request |
| `subscriptions` | Owner only | Create own pending reference |
| `poolLedger` | None | None |

Signup accepts only `displayName`, authenticated `email`, and a server timestamp for `createdAt`. Trust, streaks, badges, counts, and activity dates are backend-owned. Display names, area names, and route labels must be nonblank, trimmed strings of at most 80 characters. Saved route areas must differ, including case-insensitive comparisons.

Reports require an existing corridor, an integer price of 1–50,000 RWF, a supported time/weather value, the authenticated passenger ID, and a server creation timestamp. `reason`, `verifiedAt`, and `processedAt` may start absent or null; clients cannot subsequently change them. Clients cannot create seed reports or change status/ownership. The backend may create verified seeds with `isSeeded: true` and no `passengerId`; those reports are not client-readable.

Cash-out amounts must be positive whole points within the wallet's finalized balance. Methods match the app: `MTN MoMo` and `Airtel Money`. This validates each request, not a reservation of funds: backend approval must recheck and deduct balances atomically to prevent multiple requests spending the same points.

Subscription references must match their document IDs and the app's normalized format: 6–20 uppercase letters/numbers. The amount must equal the current 2,000 RWF Pass price. Clients cannot overwrite or delete a reference, including a rejected reference, or set approval dates/status. Initial approval dates may be absent or null.

Owner list queries on reports, wallet entries, cash-out requests, and subscriptions must filter by `passengerId == currentUid`. A public leaderboard query must use `leaderboard`, not private passenger profiles.

## Run the rules tests

Requires Node 22, Firebase CLI, and a Java runtime supported by the Firestore emulator. The Android Studio JBR was used for local validation. From the project root in PowerShell:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
npm.cmd --prefix rules_tests ci
npm.cmd --prefix rules_tests run test:emulator
```

The runner starts only Firestore using the existing `firebase.json` and project `demo-fairfare`. Tests refuse a missing/nonlocal emulator endpoint and use mock authentication plus isolated emulator fixtures. No service account or deployment is required. With an emulator already running, set `FIRESTORE_EMULATOR_HOST` to its loopback address/port and run `npm.cmd --prefix rules_tests test`.

Tests cover public/private access, owner CRUD, field allowlists, backend-only metadata/balances/status, input boundaries, seed protection, private list queries, reference reuse, and rejected batches. Emulator rules tests do not prove production indexes are deployed or that backend approvals are correct. Collection owners review the rules before deployment through the team's Firebase workflow.

Local validation: 110 emulator tests passed with Node 22.19.0, Firebase CLI 15.34.1, and Firestore emulator 1.22.0.

The app currently uses fake repositories, which do not exercise Firestore rules. Real repositories must write the documented field shapes and server timestamps.

References: [Firebase rules testing](https://firebase.google.com/docs/rules/unit-tests), [field-level write restrictions](https://firebase.google.com/docs/firestore/security/rules-fields).
