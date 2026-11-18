```mermaid
erDiagram
    direction TB

    PASSENGER ||--o{ SAVED_ROUTE : owns
    PASSENGER o|--o{ REPORT : submits
    CORRIDOR ||--o{ REPORT : receives
    CORRIDOR ||--o| CORRIDOR_STATS : summarizes
    PASSENGER ||--o| WALLET : has
    PASSENGER ||--o{ WALLET_ENTRY : earns
    REPORT ||--o| WALLET_ENTRY : rewards
    PASSENGER ||--o{ CASH_OUT_REQUEST : requests
    PASSENGER ||--o{ SUBSCRIPTION : purchases
    PASSENGER ||--o| LEADERBOARD_ENTRY : projects

    PASSENGER {
        string documentId PK
        string displayName
        string email
        string phone
        int trustScore
        int streak
        string[] badges
        int verifiedCount
        timestamp lastReportDate
        timestamp createdAt
    }
    SAVED_ROUTE {
        string ownerUid PK,FK
        string documentId PK
        string fromArea
        string toArea
        string label
        timestamp createdAt
    }
    CORRIDOR {
        string documentId PK
        string fromArea
        string toArea
        bool isSeeded
        timestamp createdAt
    }
    CORRIDOR_STATS {
        string documentId PK,FK
        int median
        int low
        int high
        int sampleSize
        string confidence
        int windowDays
        timestamp updatedAt
    }
    REPORT {
        string documentId PK
        string? passengerId FK
        string corridorId FK
        int price
        string timeSegment
        string weather
        string status
        string reason
        timestamp createdAt
        timestamp verifiedAt
        timestamp? processedAt
        bool isSeeded
    }
    WALLET {
        string documentId PK,FK
        int pendingBalance
        int finalizedBalance
        timestamp updatedAt
    }
    WALLET_ENTRY {
        string documentId PK
        string passengerId FK
        string reportId FK
        int amount
        string state
        timestamp createdAt
    }
    CASH_OUT_REQUEST {
        string documentId PK
        string passengerId FK
        int amount
        string method
        string status
        timestamp createdAt
    }
    SUBSCRIPTION {
        string documentId PK
        string passengerId FK
        string reference UK
        int amount
        string status
        timestamp startsAt
        timestamp endsAt
    }
    LEADERBOARD_ENTRY {
        string documentId PK,FK
        string displayName
        int trustScore
    }
    POOL_LEDGER {
        string documentId PK
        int rewardBalance
        int operationsBalance
        int reserveBalance
        timestamp updatedAt
    }
    NOTARIZATION {
        string documentId PK
        string hash
        string txId
        timestamp periodStart
        timestamp periodEnd
        timestamp createdAt
    }
```

![ERD](erd.png)

## Firestore mapping

| Entity | Firestore path | Passenger writes | Backend writes | App reads |
|---|---|---|---|---|
| Passenger | `passengers/{uid}` | Creates `displayName`, `email`, `createdAt`; updates `displayName` | `trustScore`, `streak`, `badges`, `verifiedCount`, `lastReportDate`; optional `phone` and email synchronization | Owner |
| Saved route | `passengers/{uid}/savedRoutes/{routeId}` | Creates `fromArea`, `toArea`, `label`, `createdAt`; edits areas/label; deletes own route | None required | Owner |
| Corridor | `corridors/{corridorId}` | None | `fromArea`, `toArea`, `isSeeded`, `createdAt` | Public |
| Corridor statistics | `corridorStats/{corridorId}` | None | `median`, `low`, `high`, `sampleSize`, `confidence`, `windowDays`, `updatedAt` | Public |
| Report | `reports/{reportId}` | Creates `passengerId`, `corridorId`, `price`, `timeSegment`, `weather`, `createdAt`, `status: pending`; edits price or deletes only while pending | `status` changes, `reason`, `verifiedAt`, `processedAt`, `isSeeded`; all seed-report fields | Owner |
| Wallet | `wallets/{uid}` | None | `pendingBalance`, `finalizedBalance`, `updatedAt` | Owner |
| Wallet entry | `walletEntries/{reportId}` | None | `passengerId`, `reportId`, `amount`, `state`, `createdAt` | Owner |
| Cash-out request | `cashOutRequests/{requestId}` | Creates `passengerId`, `amount`, `method`, `createdAt`, `status: pending` | `status` changes | Owner |
| Subscription | `subscriptions/{reference}` | Creates `passengerId`, `reference`, `amount`, `status: pending` | `status` changes, `startsAt`, `endsAt` | Owner |
| Leaderboard entry | `leaderboard/{uid}` | None | `displayName`, `trustScore`; E5 keeps the copied name synchronized when a passenger edits it | Public |
| Pool ledger | `poolLedger/main` | None | `rewardBalance`, `operationsBalance`, `reserveBalance`, `updatedAt` | None |
| Notarization | `notarizations/{notarizationId}` | None | `hash`, `txId`, `periodStart`, `periodEnd`, `createdAt` | Public |

`documentId` and saved-route `ownerUid` represent document-path keys, not stored fields. Timestamps are Firestore Timestamps. The domain layer represents them as `DateTime` values. The table defines the access contract for B2 security rules.

## Report creation

| Field | Passenger report | Backend seed report |
|---|---|---|
| `passengerId` | Authenticated passenger UID | Omitted, not stored as null |
| `status` | `pending` | `verified` |
| `isSeeded` | Omitted or `false` | `true` |
| `processedAt` | Absent or null until the backend sets it | Absent or null until the backend sets it |
| `verifiedAt` | Absent or null until verification | Verification timestamp |

The `Report` domain entity allows an absent passenger ID for seed reports. Firestore writers must omit that field for seeds. Seed reports are written by the backend and are included in corridor statistics.

## LeaderboardEntry

[`LeaderboardEntry`](../app/lib/features/profile/domain/entities/leaderboard_entry.dart) contains `id` (passenger UID), `displayName`, and `trustScore`. The backend writes the public name/score projection; private passenger fields remain in `passengers/{uid}`.
