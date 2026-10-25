# FairFare ERD — B1

Owner: Ménès (B). For team review, October 25, 2026.

Open [erd.png](erd.png) for the image or [erd.svg](erd.svg) for a zoomable version. The editable source is [erd.mmd](erd.mmd); GitHub also renders it below.

## Reading the diagram

- A box is an entity, mapped to a Firestore collection or subcollection in the data model.
- `PK` is the document's path key. `FK` is a related document's ID or an ownership path; these are logical relationships, not SQL constraints.
- `||` means exactly one, `o|` means zero or one, and `o{` means zero or many. For example, one rider owns zero or many saved routes.
- `documentId` and the saved-route `ownerUid` are **path metadata, not stored body fields**. A saved route's full key includes its parent rider path.
- Reports with no rider are server-only seed prices. App reports always have an owner.
- No relationship line is drawn from notarizations to individual riders/reports: stamps cover an aggregate snapshot. The shared pool is a singleton, not a rider-owned document.

See [the complete field and permission tables](firestore_data_model.md) for nullable fields, enum values, and collection paths. Review [the proposed changes and open decisions](b1_review.md) before adopting them.

Exports use Mermaid CLI 12.0.0, neutral theme, size 3600, and PNG scale 2.

## Complete field diagram

```mermaid
erDiagram
    direction TB

    RIDER ||--o{ SAVED_ROUTE : owns
    RIDER o|--o{ REPORT : submits
    CORRIDOR ||--o{ REPORT : receives
    CORRIDOR ||--o| CORRIDOR_STATS : summarizes
    RIDER ||--o| WALLET : has
    RIDER ||--o{ WALLET_ENTRY : earns
    REPORT ||--o| WALLET_ENTRY : rewards
    RIDER ||--o{ CASH_OUT_REQUEST : requests
    RIDER ||--o{ SUBSCRIPTION : purchases
    RIDER ||--o| LEADERBOARD_ENTRY : projects

    RIDER {
        string documentId PK "PATH: Firebase Auth uid"
        string displayName
        string email "Private"
        string phone "Optional; private; reserved"
        int trustScore "Server; initially absent"
        int streak "Server; initially absent"
        string[] badges "Server; initially absent"
        int verifiedCount "Server; initially absent"
        timestamp lastReportDate "Server; absent or null initially"
        timestamp createdAt
    }
    SAVED_ROUTE {
        string ownerUid PK,FK "PATH: parent riders uid; not stored"
        string documentId PK "PATH: auto ID within parent"
        string fromArea
        string toArea
        string label
        timestamp createdAt
    }
    CORRIDOR {
        string documentId PK "PATH: directional area slug"
        string fromArea
        string toArea
        bool isSeeded
        timestamp createdAt
    }
    CORRIDOR_STATS {
        string documentId PK,FK "PATH: corridor ID"
        int median
        int low
        int high
        int sampleSize
        string confidence
        int windowDays
        timestamp updatedAt
    }
    REPORT {
        string documentId PK "PATH: auto ID; deterministic for seeds"
        string riderId FK "Null only for server seed reports"
        string corridorId FK
        int price
        string timeSegment
        string weather
        string status
        string reason "Server; absent or null until rejection"
        timestamp createdAt
        timestamp verifiedAt "Server; absent or null until verified"
        bool isSeeded "Server; absent means false"
    }
    WALLET {
        string documentId PK,FK "PATH: rider uid"
        int pendingBalance
        int finalizedBalance
        timestamp updatedAt
    }
    WALLET_ENTRY {
        string documentId PK "PATH: report ID prevents duplicate rewards"
        string riderId FK
        string reportId FK
        int amount
        string state
        timestamp createdAt
    }
    CASH_OUT_REQUEST {
        string documentId PK "PATH: auto ID"
        string riderId FK
        int amount
        string method
        string status
        timestamp createdAt
    }
    SUBSCRIPTION {
        string documentId PK "PATH: payment reference"
        string riderId FK
        string reference UK "Must equal document ID"
        int amount
        string status
        timestamp startsAt "Server; absent or null until active"
        timestamp endsAt "Server; absent or null until active"
    }
    LEADERBOARD_ENTRY {
        string documentId PK,FK "PATH: rider uid; proposed collection"
        string displayName
        int trustScore
    }
    POOL_LEDGER {
        string documentId PK "PATH: main; proposed singleton"
        int rewardBalance
        int operationsBalance
        int reserveBalance
        timestamp updatedAt
    }
    NOTARIZATION {
        string documentId PK "PATH: auto ID"
        string hash
        string txId
        timestamp periodStart
        timestamp periodEnd
        timestamp createdAt
    }
```
