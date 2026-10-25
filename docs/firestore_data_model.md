# FairFare Firestore data model — B1 proposal

Owner: Ménès (Person B). October 25, 2026. **For team review.**

Start with [the ERD](erd.md). This document defines the proposed stored fields and write permissions, based on the Flutter roadmap §2.3, engine logic specification, team task guide B1, and meeting notes.

The model provides the contract for the feature collections and B2 security rules. It has not been deployed.

## How to read this model

- A **collection** contains documents. A **document** contains fields. A **subcollection** belongs under a document.
- The document ID is the diagram's primary key (PK). It is path metadata, not an extra stored `id` field. Flutter entities obtain `id` from the document snapshot.
- Foreign keys (FK) here are string IDs or parent path IDs. Firestore does not enforce SQL foreign keys or cascade deletes. B2 rules and server transactions must enforce the intended relationships.
- `Owner` means the Firebase Auth user whose UID owns the document, not any signed-in user. `Server` means the trusted NestJS service/seed script using the Admin SDK.
- All dates use Firestore Timestamp values, not formatted strings. Client creation timestamps use a server timestamp. Missing nullable server fields are treated as null by readers.
- Prices and subscription amounts are whole RWF. Wallet amounts are whole demo points. No floating-point balances. See the proposed pool accounting convention below.
- `documentId` and saved-route `ownerUid` appear in the ERD only to describe paths. They must not be written as body fields.

## Collection paths and access

| Entity | Firestore path | ID source | App reads | App writes |
|---|---|---|---|---|
| Rider | `riders/{uid}` | Firebase Auth UID | Owner only | Create own basic profile; update own display name |
| Saved route | `riders/{uid}/savedRoutes/{routeId}` | Auto ID within rider | Owner only | Own create, read, update, delete |
| Corridor | `corridors/{corridorId}` | Directional slug, e.g. `kacyiru_kimironko` | Public | None |
| Corridor statistics | `corridorStats/{corridorId}` | Same ID as corridor | Public | None |
| Fare report | `reports/{reportId}` | Auto ID; fixed ID for seed records | Owner only | Create pending; update price or delete while pending |
| Wallet | `wallets/{uid}` | Same UID as rider | Owner only | None |
| Wallet entry | `walletEntries/{reportId}` | Same ID as rewarded report (proposal) | Owner only | None |
| Cash-out request | `cashOutRequests/{requestId}` | Auto ID | Owner only | Create own pending request |
| Subscription | `subscriptions/{reference}` | Payment reference | Owner only | Create own pending request |
| Leaderboard entry | `leaderboard/{uid}` | Same UID as rider (proposal) | Public | None |
| Pool ledger | `poolLedger/main` | Singleton `main` (proposal) | None | None |
| Notarization | `notarizations/{notarizationId}` | Auto ID | Public | None |

The server maintains all data the app cannot write. No client deletion of riders, corridors, rewards, subscriptions, or audit records is proposed. Account deletion needs a separately reviewed retention/cleanup policy.

## Stored fields

`Required` means present in the completed document unless explicitly described as optional or initialized later. Fields not listed are outside this draft and must be reviewed before they are added. Client writes will use explicit field allowlists in B2.

### `riders/{uid}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `displayName` | string, required | Owner at signup and later edits; trim and reject blank |
| `email` | string, required | Owner at signup, matching authenticated email; later synchronization is server controlled |
| `phone` | string, optional | Reserved from the roadmap; server only for now, no phone signup UI |
| `createdAt` | Timestamp, required | Owner at signup using server timestamp; immutable |
| `trustScore` | int, initialized by server | Server only; 0–100, default 0 |
| `streak` | int, initialized by server | Server only; nonnegative, default 0 |
| `badges` | array of strings, initialized by server | Server only; distinct badge IDs, default empty |
| `verifiedCount` | int, initialized by server | Server only; nonnegative, default 0 |
| `lastReportDate` | Timestamp or null, initialized by server | Server only; null until eligible activity |

Signup creates only `displayName`, `email`, and `createdAt`, as B4 requires. The server initializes score fields; profile readers must use defaults while that initialization is pending. Firebase Auth stores passwords and email verification state: never store either a password or an editable `emailVerified` flag here. Email verification is read from Firebase Auth.

Proposed badge IDs are `corridorPioneer`, `weekStreak`, and `tenVerified`. Streak comparisons use calendar days in Africa/Kigali; the server stores timestamps and implements that day boundary consistently. E owns final badge/streak rules.

### `riders/{uid}/savedRoutes/{routeId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `fromArea` | string, required | Owner; trimmed, nonblank |
| `toArea` | string, required | Owner; trimmed, nonblank; different from `fromArea` after normalization |
| `label` | string, required | Owner; trimmed, nonblank; app may suggest a route label |
| `createdAt` | Timestamp, required | Owner on create using server timestamp; immutable |

Ownership comes from the parent `riders/{uid}` path, so no duplicated `riderId` field is needed. The key is the full path, not a globally unique route ID. Changing a label or areas does not change `createdAt`.

Proposed convention: routes are directional. Kacyiru → Kimironko and Kimironko → Kacyiru have separate corridor IDs. Saved routes keep the roadmap's area fields rather than requiring a new corridor foreign key. The corridor feature resolves those areas when a saved route is opened; missing coverage gets an empty state. A and B must confirm shared area normalization before implementing this lookup.

### `corridors/{corridorId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `fromArea` | string, required | Server; canonical pickup area |
| `toArea` | string, required | Server; canonical destination, different from pickup |
| `isSeeded` | bool, required | Server; identifies starter corridors |
| `createdAt` | Timestamp, required | Server; immutable creation time |

The slug belongs in the document ID, not a duplicated field. Slugs must be deterministic and agree with the shared area normalization convention.

### `corridorStats/{corridorId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `median` | int, required | Server; RWF; proposed rounding down for an even sample's midpoint |
| `low` | int, required | Server; minimum RWF in eligible rolling window |
| `high` | int, required | Server; maximum RWF; `low <= median <= high` |
| `sampleSize` | int, required | Server; positive count backing the stored statistics |
| `confidence` | string, required | Server; proposed `new`, `limited`, or `wellCovered` |
| `windowDays` | int, required | Server; positive, proposed 14 |
| `updatedAt` | Timestamp, required | Server; last recomputation |

There is at most one stats document per corridor. No eligible prices means no stats document; the server removes stale statistics instead of inventing a zero fare. Proposed confidence: `new` below 5 reports, `limited` for 5–19, `wellCovered` from 20. A confirms the thresholds and rounding.

This is an intentional materialized summary of recent verified/seed prices. It avoids fetching every report on every fare lookup. The full report history remains in `reports`; aggregating it does not make these records independent sources of truth.

The supplied design stores one summary per corridor, without segment/weather fields. Keep that contract for this draft. Whether band checking uses this baseline with multipliers or requires separate segment statistics is an A/C review question; do not claim these documents already store segment-specific prices.

### `reports/{reportId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `riderId` | string, required; null only for server seeds | Owner on create; must equal auth UID; immutable |
| `corridorId` | string, required | Owner on create; references an existing corridor; immutable |
| `price` | int, required | Owner on create and pending edits; positive whole RWF; B2/C agree upper bound |
| `timeSegment` | string, required | Owner on create; `morning`, `midday`, `evening`, `lateNight`; immutable |
| `weather` | string, required | Owner on create; `clear` or `heavyRain`; immutable |
| `status` | string, required | Owner may create only `pending`; thereafter server only: `pending`, `verified`, `rejected`, `expired` |
| `reason` | string or null, optional until server writes | Server only; nonblank rejection explanation when rejected |
| `createdAt` | Timestamp, required | Owner on create using server timestamp; immutable |
| `verifiedAt` | Timestamp or null, optional until verified | Server only; required timestamp when verified |
| `isSeeded` | bool, optional; absence means false | Server only; true marks a seed price (proposal) |

Only a report's owner may edit its price or delete it, and only when its stored status is still `pending`. The server must re-read the latest pending price in its verification transaction so an edit cannot race verification unnoticed.

Proposed seed convention: A writes deterministic IDs, `isSeeded: true`, `riderId: null`, and `status: verified`. Seeds enter statistics but never corroborate a real rider's report, earn rewards, change trust, or enter the leaderboard. This avoids inventing fake rider accounts. All app reports require an authenticated `riderId`; a client cannot set `isSeeded`. A/C/D/E must review this addition and seed filtering before adoption.

Worker claims, leases, band-check markers, and durable event-delivery records are not specified by the supplied field table. C must define their fields/collections with A, D, and E before the engine contract is frozen. A claim flag alone is not proof that all downstream rewards/trust updates completed exactly once.

### `wallets/{uid}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `pendingBalance` | int, required | Server only; nonnegative demo points |
| `finalizedBalance` | int, required | Server only; nonnegative demo points |
| `updatedAt` | Timestamp, required | Server only; last balance change |

Zero or one wallet per rider; it may not exist before initialization/first reward. A missing wallet renders as zero balances. Balances and wallet entries change atomically on the server.

### `walletEntries/{reportId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `riderId` | string, required | Server only; references rewarded rider |
| `reportId` | string, required | Server only; references verified non-seed report; equals document ID |
| `amount` | int, required | Server only; nonnegative demo points; immutable original reward |
| `state` | string, required | Server only; proposed `pending`, `finalized`, `reversed` |
| `createdAt` | Timestamp, required | Server only; reward creation time; immutable |

Using the report ID rather than an auto ID is a proposed change: one reward entry per report. The reward transaction must check whether the entry already exists before modifying the wallet/pool. A deterministic ID is only one part of preventing duplicate effects. The hold uses `createdAt`; D owns finalization and reversal logic. `reversed` represents the engine spec's invalidation case and needs D's confirmation.

### `cashOutRequests/{requestId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `riderId` | string, required | Owner on create; must equal auth UID; immutable |
| `amount` | int, required | Owner on create; positive demo points; immutable |
| `method` | string, required | Owner on create; proposed `momo` or `airtel`; immutable |
| `status` | string, required | Owner creates `pending`; server later sets `paid` or `rejected` |
| `createdAt` | Timestamp, required | Owner on create using server timestamp; immutable |

UI validation alone does not protect balances. B2 checks a request against the wallet, and any server approval must atomically check available funds before deducting/marking paid. Multiple pending requests must not allow multiple approvals against the same points. Real cash transfers are outside the course demo. D confirms method values and approval handling.

### `subscriptions/{reference}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `riderId` | string, required | Owner on create; must equal auth UID; immutable |
| `reference` | string, required | Owner on create; must equal path ID; immutable |
| `amount` | int, required | Owner on create; expected whole RWF amount; server verifies against payment evidence |
| `status` | string, required | Owner creates `pending`; server alone sets `active` or `rejected` |
| `startsAt` | Timestamp or null, optional until approved | Server only; required for active subscription |
| `endsAt` | Timestamp or null, optional until approved | Server only; after `startsAt`; proposed 30 days later |

Reference is repeated as a body field to preserve the supplied repository/entity contract; B2 requires it to equal the ID. A client may create but cannot replace, update, or delete this document. Existing references cannot be reused, even if rejected/expired. Approval must check pending status and update the pool transactionally to prevent replay. E confirms reference normalization, allowed characters, and the subscription amount before B2 is finalized.

### `leaderboard/{uid}` — proposed privacy correction

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `displayName` | string, required | Server only; projection of rider display name |
| `trustScore` | int, required | Server only; projection of rider score, 0–100 |

The roadmap suggests public leaderboard fields within private rider documents. **Firestore reads whole documents; security rules cannot conceal `email` while exposing only `displayName` and `trustScore`.** Therefore keep `riders` owner-readable and publish only these two fields in a separate collection. E's leaderboard repository reads this collection and maps the path UID to its domain model; it must not fetch private profiles for other riders.

This deliberate projection duplicates two public values for privacy. The server synchronizes the score when trust changes, the name when the owner updates it, and removes entries for ineligible/deleted accounts. E confirms that synchronization path before implementation. Never copy email, phone, payment references, or wallet balances here.

### `poolLedger/main` — proposed engine accounting summary

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `rewardBalance` | int, required | Server only; nonnegative reward budget |
| `operationsBalance` | int, required | Server only; nonnegative accumulated operations share |
| `reserveBalance` | int, required | Server only; nonnegative accumulated reserve share |
| `updatedAt` | Timestamp, required | Server only; last accounting change |

The engine spec requires pool accounting but omits its collection/field names. This singleton proposes those names; it is a balance summary, not a complete financial audit journal. Initialize balances to zero. Payment approval credits the 35/45/20 split once per subscription; reward creation debits the reward balance in the same transaction as wallet updates. No app read or write access.

Proposed course convention: allocate payment amounts as integer budget units at one unit per RWF, and consume one budget unit per demo point. This is internal simulated accounting, not a promise of cash redemption. D/E must confirm the unit conversion, split rounding that preserves the total, and whether extra ledger history is needed before implementation.

### `notarizations/{notarizationId}`

| Field | Type / presence | Writer and constraint |
|---|---|---|
| `hash` | string, required | Server only; SHA-256 of canonical aggregate snapshot |
| `txId` | string, required | Server only; Cardano testnet transaction ID |
| `periodStart` | Timestamp, required | Server only; beginning of covered period |
| `periodEnd` | Timestamp, required | Server only; at or after `periodStart` |
| `createdAt` | Timestamp, required | Server only; record creation |

This is an aggregate snapshot stamp: no rider/report foreign key and no personal data. One stamp can cover many corridor summaries. `txId` is required in this baseline; if A needs to store a hash before a transaction exists, add a reviewed nullable/pending contract first.

## Queries and indexes

Deployable composite definitions are in [`../firestore.indexes.json`](../firestore.indexes.json). They are a proposed query plan, not evidence of deployment. `ASC`/`DESC` below correspond to Firebase `ASCENDING`/`DESCENDING`.

| Collection | Query | Composite index fields in order |
|---|---|---|
| `reports` | Eligible corridor prices in rolling window | `corridorId ASC`, `status ASC`, `createdAt ASC` |
| `reports` | Own reports, newest first | `riderId ASC`, `createdAt DESC` |
| `reports` | Pending reports for corroboration in the same time segment | `corridorId ASC`, `status ASC`, `timeSegment ASC`, `createdAt ASC` |
| `reports` | Expiry sweep | `status ASC`, `createdAt ASC` |
| `walletEntries` | Own reward history, newest first | `riderId ASC`, `createdAt DESC` |
| `walletEntries` | Pending entries past the hold | `state ASC`, `createdAt ASC` |
| `cashOutRequests` | Own requests, newest first | `riderId ASC`, `createdAt DESC` |

Single-field queries use Firestore's default indexes: `leaderboard` ordered by `trustScore DESC` with limit 10; subscriptions filtered by `riderId`; saved routes ordered by `createdAt` within the current rider's subcollection. A descending leaderboard field does not need a one-field *composite* index. The original roadmap's `riders` ranking query moves to `leaderboard` for privacy.

Owner list queries must constrain `riderId == currentUid` on top-level private collections. Server seed filtering can happen in memory after the indexed query. Finalize each actual `where`/`orderBy` combination with its feature owner and verify on the target Firestore project; a local JSON check does not prove query availability. Multiple subscriptions can exist for one rider, so the repository must define which active/pending pass it shows rather than assuming the query returns one record.

## Relationships, consistency, and review

- One rider has many saved routes, reports, wallet entries, cash-out requests, and subscriptions. A real rider report has exactly one owner; server seeds have none.
- One corridor has many reports and zero or one current statistics document.
- One rider has zero or one wallet and public leaderboard document while initialization is pending.
- One non-seed verified report has at most one reward entry; pending/rejected/expired reports have none.
- `poolLedger/main` is shared accounting state, not a child of a particular rider or subscription. Notarizations cover aggregate snapshots, not individual records.
- Stored field names, metadata keys, and relationships in the ERD must stay synchronized with this document and the roadmap addendum as implementation evolves.

Confirm the open decisions in [the review checklist](b1_review.md) before finalizing the model. Security rules and their tests are part of B2.

## Technical references

- [Firebase: document-level read access and field restrictions](https://firebase.google.com/docs/firestore/security/rules-fields#allowing_read_access_only_for_specific_fields) — reason for separate private/public documents; field allowlists for B2.
- [Firebase: index types](https://firebase.google.com/docs/firestore/query-data/index-overview) — single-field defaults and composite indexes.
- [Mermaid: entity relationship diagrams](https://mermaid.js.org/syntax/entityRelationshipDiagram.html) — keys, attributes, and relationship notation.
