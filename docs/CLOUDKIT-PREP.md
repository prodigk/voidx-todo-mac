# CloudKit Preparation

VoidX Todo will use CloudKit as the Apple-platform sync layer for todos, notes, and categories.
The current app still reads and writes the local JSON file first; CloudKit support should be added as a sync layer after the local model boundary is stable.

## Container

- Container identifier: `iCloud.com.voidx.todo`
- Database: private CloudKit database
- Entitlements:
  - `Entitlements/VoidXTodoMac.entitlements`
  - `Entitlements/VoidXTodoWidget.entitlements`

The container must be created and attached in Apple Developer / Xcode before CloudKit calls are enabled.

## Record Types

Use one CloudKit record per app entity. Keep record names equal to local UUID strings so local JSON, CloudKit, widgets, and future mobile apps can refer to the same object IDs.

### Todo

- `title`: String
- `detail`: String
- `dueDate`: Date
- `isCompleted`: Int64 or Bool
- `priority`: String
- `categoryID`: String
- `scheduleScope`: String
- `recurrenceRuleJSON`: Bytes
- `completedAt`: Date
- `completedOccurrenceDatesJSON`: Bytes
- `createdAt`: Date
- `updatedAt`: Date
- `deletedAt`: Date, optional tombstone

### Category

- `name`: String
- `colorIndex`: Int64
- `createdAt`: Date
- `updatedAt`: Date
- `deletedAt`: Date, optional tombstone

### Note

- `title`: String
- `body`: String
- `categoryID`: String
- `createdAt`: Date
- `updatedAt`: Date
- `deletedAt`: Date, optional tombstone

## Migration Plan

1. Keep `LocalAppDataRepository` as the offline source used by `TodoStore`.
2. Add a `CloudKitSyncService` that can push local records and pull remote records.
3. On first CloudKit enablement, upload local JSON data using UUID-based record names.
4. Store sync metadata locally: last sync date and CloudKit server change tokens.
5. Merge remote changes into local JSON, then refresh `TodoStore`.
6. Use `updatedAt` as the first conflict policy. The newest update wins.
7. Represent deletes with `deletedAt` tombstones so another device can observe the deletion.

## Future Web Access

CloudKit is a good fit for Apple-device sync and a future iOS app. For a public web app, prefer a small backend that reads CloudKit on behalf of the signed-in Apple user, or revisit the storage choice if non-Apple accounts become a requirement.
