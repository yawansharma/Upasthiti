# 09 — API Architecture

## Overview

upasthiti does not expose any public-facing REST API. All data operations use the **Appwrite SDK** (which itself communicates with the Appwrite REST API internally), and AI inference uses direct HTTP calls to the Hugging Face Spaces ML backend.

There is no API gateway, no middleware layer, and no custom HTTP server. The Appwrite project's permission policies define what data the app can read and write.

---

## Appwrite SDK Operations Used

The application uses the Appwrite Databases SDK (`Databases` class) for all data operations. Key query patterns:

### Read Patterns

| Operation | Method | Example Usage |
|---|---|---|
| Fetch by field value | `listDocuments` + `Query.equal(field, value)` | Login: `Query.equal('username', id)` |
| Fetch all in collection | `listDocuments` + `Query.limit(n)` | Admin logs: limit 500 |
| Ordered fetch | `listDocuments` + `Query.orderDesc('field')` | Logs: `Query.orderDesc('timestamp')` |
| Multi-filter | Multiple `Query.*` in list | Leave: level + status + approverId |
| Cursor pagination | `Query.cursorAfter(lastDocId)` | Infinite scroll in admin logs |
| Greater/less than | `Query.greaterThanEqual`, `Query.lessThan` | Date range filtering on logs |
| Array contains | `Query.equal('field', [list])` | Special role batch fetch: role in list |

### Write Patterns

| Operation | Method | Usage |
|---|---|---|
| Create document | `createDocument` with `ID.unique()` | New class, leave request, attendance log |
| Update document | `updateDocument` with changed fields | Approve leave, update status, soft-delete |
| Delete document | `deleteDocument` | Hard delete of inactive user accounts |

### Storage Patterns

| Operation | Usage |
|---|---|
| `storage.createFile(bucketId, ID.unique(), file)` | Upload profile photo, attendance photo, community file |
| `storage.deleteFile(bucketId, fileId)` | Delete profile photo on account cleanup |
| `storage.getFileView(bucketId, fileId)` | Get direct URL for displaying profile photos |

---

## ML Backend API

### POST /register-face
**Host**: `https://pasteshub404-navikarana-backend.hf.space`

**Request**:
```
Content-Type: multipart/form-data
Fields:
  username: string (the user's unique ID)
  image: file (JPEG or PNG selfie)
```

**Response (success)**:
```json
{"status": "registered"}
```

**Called by**: `register_page.dart` during onboarding.

---

### POST /login-face
**Host**: `https://pasteshub404-navikarana-backend.hf.space`

**Request**:
```
Content-Type: multipart/form-data
Fields:
  username: string (the user's unique ID)
  image: file (live attendance photo)
```

**Response (success)**:
```json
{"verified": true}
```

**Response (failure)**:
```json
{"error": "Face not recognized"}
```

**Called by**: `class_detail_page.dart` during attendance marking.

**Retry behaviour**: 3 attempts with 3/6/9 s delays; 60 s per-request timeout.

---

## Realtime API (WebSocket)

Appwrite Realtime uses a WebSocket connection. Subscriptions are created with `AppwriteService.realtime.subscribe([channel])`.

### Channel Format
```
databases.{databaseId}.collections.{collectionId}.documents
```

### Active Subscriptions

| Screen | Channel | Events Handled |
|---|---|---|
| `HomePage` | `classes` | Class create/update/delete |
| `AdminHomePage` | `attendance_logs` | New attendance entries |
| `AdminApprovalRequestsPage` | `users` | New pending registrations |
| `CommunityPage` | `community_messages` | New messages in channel or DM thread |
| `AdminDistributionTab` | `distribution_events` | Event status changes |

Each subscription calls `_fetchData()` on any received event (coarse-grained, not event-type-specific). This is a simplification that avoids complex merge logic at the cost of a full re-fetch on any change.

---

## QR Code Encoding

Distribution QR codes are generated and decoded by `DistributionService`:
- `encodeQr(username)` — returns the raw username string as the QR payload.
- `decodeQr(qrString)` — parses the scanned string back to a username.

Currently the encoding is direct (username = QR content). A future improvement could include HMAC signing to prevent QR forgery.

---

## Error Handling Strategy

The application uses Dart `try/catch` blocks in all async service calls. Error handling follows these patterns:
- **User-facing errors**: `ScaffoldMessenger.showSnackBar()` with the error message.
- **Background/cleanup errors**: Caught silently (empty `catch` block) so they never interrupt the main flow.
- **ML API errors**: Returned as error strings, shown to the user, and attendance is blocked.
- **Missing approver errors**: Specific user message instructing them to contact their admin.

No error telemetry, logging service, or crash reporting system is present in the codebase.
