# 07 — Backend Architecture

## Backend Provider: Appwrite

upasthiti uses **Appwrite Cloud** as its sole backend. There is no custom server-side application code. All data operations, file storage, and realtime event delivery are handled entirely by Appwrite's managed cloud service running in the **Singapore region** (`sgp.cloud.appwrite.io`).

The choice of Appwrite as a BaaS eliminates the need to write, deploy, or maintain server infrastructure. All database access controls, file storage policies, and realtime subscriptions are configured through the Appwrite console.

---

## AppwriteService Singleton

`lib/services/appwrite_service.dart` is the central service class. It initialises and exposes static instances:

```
Client  → configured with endpoint + projectId
Databases → Appwrite Databases SDK
Storage   → Appwrite Storage SDK
Realtime  → Appwrite Realtime SDK
```

All SDK instances are static — created once and shared across the entire application. There is no dependency injection framework; services reference `AppwriteService.databases` directly.

### Configuration Constants (non-sensitive)
| Constant | Value |
|---|---|
| Endpoint | `https://sgp.cloud.appwrite.io/v1` |
| Database ID | `6a2c10dc000d5e50f314` |
| Profile Photos Bucket | `6a2c12a500260c940843` |
| Attendance Photos Bucket | `attendance_photos` (by name) |
| Community Files Bucket | `community_files` (by name) |
| ML Backend Base URL | `https://pasteshub404-navikarana-backend.hf.space` |

---

## Service Layer Responsibilities

### `LeaveService` (`lib/services/leave_service.dart`)
Provides typed CRUD operations for the `leave_requests` collection:
- `submitRequest()` — creates a leave document with all metadata including the resolved approverId.
- `getPendingRequests(level, {approverId})` — fetches pending requests for a given approver level, optionally filtered by specific approver ID.
- `getMyRequests(userId)` — fetches all leave records for a single user.
- `updateStatus(documentId, status, ...)` — transitions a request to approved/rejected and records who acted.

The service implements backward-compatible approver scoping: requests created before the `approverId` field was introduced (no `approverId` stored) are still visible to any admin at the correct level, preventing orphaned requests.

### `DistributionService` (`lib/services/distribution_service.dart`)
Manages four Appwrite collections: `distribution_events`, `event_recipients`, `event_admin_assignments`, `distribution_scan_logs`.

Key operations:
- `createEvent()` / `updateEventStatus()` — event lifecycle management.
- `addRecipient()` / `bulkAddRecipients()` — recipient list management.
- `processScan(eventId, scannedUserId, scannerAdminId)` — core distribution logic; validates authorization, eligibility, and updates status atomically.
- `encodeQr(username)` / `decodeQr(qrString)` — encode/decode QR payload (currently raw username).
- `getAdminActiveEvents(adminId)` — fetches events where admin is assigned as scanner.
- `acknowledgeReceipt(recipientDocId)` — student acknowledgement step.

The `ScanStatus` enum defines all possible scan outcomes: `success`, `alreadyIssued`, `notInList`, `eventNotActive`, `notAuthorized`, `revoked`.

### `AdminHierarchyService` (`lib/services/admin_hierarchy_service.dart`)
Resolves the administrative hierarchy embedded in class documents:

- `readAssignments(classData)` — extracts `headAdminId`, `supervisorId` from the class document, checking both top-level fields and the `boundary` JSON blob (dual-storage for resilience).
- `geoFromBoundary(boundary)` — strips assignment metadata keys from the boundary JSON to return only geographic data.
- `fetchClassesForAdmin(adminId, level)` — returns classes where the admin is creator, head, or supervisor.
- `resolveApprovers(requesterId, requesterLevel)` — traverses class assignments upward to find the correct leave approver.
- `persistClassAssignments(...)` — writes assignment metadata into both the class document's top-level fields and the `boundary` JSON for compatibility.
- `listAdminsByLevel(level, {department})` — queries the `users` collection filtered by `role: admin` and `level`.

---

## ML Backend

The AI face recognition service is a separately maintained Python application deployed on Hugging Face Spaces. The Flutter app communicates with it via standard HTTP:

### Endpoint: POST /register-face
- **Request**: `multipart/form-data` with fields `username` (String) and `image` (file)
- **Success**: HTTP 200 with JSON `{"status": "registered"}`
- **Use case**: Called once during student registration

### Endpoint: POST /login-face
- **Request**: `multipart/form-data` with fields `username` (String) and `image` (file)
- **Success**: HTTP 200 with JSON `{"verified": true}`
- **Failure**: HTTP 200 with JSON `{"error": "Face not recognized"}` or similar
- **Use case**: Called on every attendance mark attempt

### Resilience
A 3-attempt retry loop with 3/6/9-second backoff handles the Hugging Face Spaces cold-start delay. Each request carries a 60-second timeout. If all 3 retries fail, the attendance attempt is aborted with an error message.

---

## Background Operations

### Inactive Account Cleanup
`AppwriteService.cleanupInactiveAccounts({int inactiveDays = 60})` is triggered during the admin login flow. It:
1. Queries `users` where `lastLogin < cutoffDate` (batches of 50 via `Query.limit`).
2. Deletes the profile picture from Storage.
3. Deletes the user document from the database.

This runs fire-and-forget (`try/catch` suppresses all errors) so it never blocks the login flow.

### No Message Queues or Scheduled Jobs
The application has no background queue system, no cron jobs, and no server-side functions. All operations are initiated client-side. The account cleanup is the closest thing to a background task, but it is synchronously triggered by the admin login flow.

---

## Limitations Inferred from Code

- **No server-side validation**: All business rule enforcement (geofence, time window, leave routing) happens client-side. A malicious client could potentially bypass these checks if it had direct Appwrite API access with the project credentials.
- **No Appwrite Functions**: There are no Appwrite Cloud Functions configured in the codebase. All logic runs on the client.
- **Hardcoded project IDs**: Project and database IDs are hardcoded in `AppwriteService`. There is no `.env` or environment configuration system.
- **No caching layer**: There is no in-memory cache or local database. Every screen loads data fresh from Appwrite on `initState()`.
