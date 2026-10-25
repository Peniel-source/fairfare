# B1: database design review

Owner: Ménès (B). Branch: `menes`. Status: ready for team review.

Read the [data model](firestore_data_model.md) alongside the [ERD](erd.md).

## Design changes to review

| Change | Reason | Reviewers |
|---|---|---|
| Add `verifiedCount` and `lastReportDate` to riders | Support badges and streaks | B, E |
| Keep riders private; add public `leaderboard/{uid}` | Expose names and scores without exposing email/phone | B, E |
| Define `poolLedger/main` | Store shared payment/reward balances | A, D, E |
| Use the report ID as the wallet entry ID | Support one reward entry per report | C, D |
| Identify seed reports with `isSeeded`, with no rider | Include seed prices in statistics without rewarding them | A, C, D, E |
| Add query indexes and shared collection constants | Keep feature queries and paths consistent | Feature owners |

The roadmap copy includes a B1 addendum covering these proposals.

## Decisions to confirm

- [ ] A/B: corridor direction and area normalization.
- [ ] A: seed record format, median rounding, confidence labels, and empty-window behavior.
- [ ] A/C: per-corridor baseline versus segment-specific band statistics.
- [ ] B/C: report price limits and email-verification requirements.
- [ ] C/A/D/E: processing fields and reliable delivery of verification events.
- [ ] D: reward reversal states, cash-out methods, and concurrent approvals.
- [ ] D/E: pool units, split rounding, and accounting history.
- [ ] E: rider initialization, public leaderboard synchronization, and subscription reference/current-pass selection.
- [ ] A: whether notarizations need a pending state before a transaction ID exists.

## Validation

- ERD rendered to PNG and SVG; layout checked.
- All 12 entities match the field tables and collection constants.
- Seven composite index definitions checked for valid structure and field names.
- Roadmap DOCX checked for a valid archive and XML.
- Dart formatting and analysis passed for `firestore_paths.dart`.

Live index/query checks and security rules tests are still to come with Firebase setup and B2. Full Flutter/backend test suites were not run for this documentation/constants change.

Open one B1 PR into `dev` and request Peniel's review. Ask the affected feature owners to confirm their schema decisions before the model is finalized.
