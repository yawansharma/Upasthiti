# 03 — Complete Feature List

This document enumerates every confirmed feature present in the codebase, organised by functional domain.

---

## A. Authentication & Account Security

| Feature | Detail |
|---|---|
| **Animated Splash Screen** | Logo fades/scales in (1.5 s, easeOutBack), fades/scales out (1 s), 800 ms crossfade to login |
| **Employee Login** | Username + password; dual-mode SHA-256 / plaintext verifier with silent hash upgrade |
| **Admin Login** | Dedicated portal with level/role enforcement; math CAPTCHA required before credential submission |
| **Dean Secret Access** | Hidden: 5 rapid taps on app logo reveals "Super Admin" button — not visible in normal UI |
| **Forgot Password — Step 1** | User enters Unique ID; system fetches security question from DB |
| **Forgot Password — Step 2** | Security answer verified (case-insensitive); blocks if no question was ever set |
| **Forgot Password — Step 3** | New password set; hashed with SHA-256 before storage |
| **Profile Settings** | Change password; update security question and answer |
| **lastLogin Tracking** | Timestamp recorded on every successful login for audit and cleanup purposes |
| **RBAC Enforcement** | Role checked on login; role-specific pages reject wrong roles at the DB query level |
| **Inactive Account Cleanup** | Background routine deletes DB record + Storage photo for accounts inactive > 60 days |

---

## B. Student / Employee Home

| Feature | Detail |
|---|---|
| **My Classes** | Shows enrolled classes with realtime subscription |
| **Invited Classes** | Classes where admin directly added username to invite list |
| **Pending Requests** | Classes where join request awaits admin approval; badge shown |
| **Rejected Requests** | Classes where join request was explicitly rejected |
| **Explore Department** | Browse classes in the user's department to submit join requests |
| **New Class Acceptance Notification** | Auto-detected new enrollment between fetches; animated in-app dialog, auto-dismisses in 4 s |
| **Realtime Updates** | Appwrite Realtime subscription on `classes` collection; no manual refresh required |

---

## C. Class Detail Page (Student)

| Feature | Detail |
|---|---|
| **Class Metadata Display** | Name, class code, admin name, department |
| **Attendance History** | Chronological log of the student's own marks for this class |
| **Attendance Period Status** | Shows whether a period is currently active |
| **Mark Attendance** | Triggers geofence → camera → AI verify → upload → log creation pipeline |
| **Leave Request Entry** | Navigate to leave submission form from class context |
| **Community Access** | Navigate to class messaging from class card |

---

## D. Attendance System

| Feature | Detail |
|---|---|
| **Time-Bounded Periods** | Admin creates periods with start/end time; ±10-minute grace window |
| **GPS Geofence Check** | Haversine distance calculation; blocks if outside radius |
| **AI Face Verification** | Live photo → Hugging Face `/login-face` API → verified/blocked |
| **Photo Upload** | Verified photo stored in `attendance_photos` Appwrite bucket |
| **Attendance Log Creation** | Document in `attendance_logs` with username, classId, periodId, timestamp, photoUrl, geofence result |
| **Admin Verification** | Admin can override `adminVerifiedStatus` to Present, Verified, or Absent |
| **isWithinGeofence Flag** | Boolean stored per-log; surfaced in Security Admin anomaly detector |
| **isHiddenFromAdmin** | Soft-delete flag; logs can be hidden without physical deletion |

---

## E. Geofencing

| Feature | Detail |
|---|---|
| **Interactive Boundary Map** | OpenStreetMap (flutter_map) with tap-to-set-centre and radius slider (30–500 m) |
| **Stored as JSON** | Boundary serialised as `{"lat":..., "lng":..., "radiusMeters":...}` in class document |
| **Admin Hierarchy Metadata** | Same `boundary` JSON field also carries `headAdminId`, `supervisorId` (separate keys) |
| **"Use My Location" Fallback** | Centre defaults to admin's current GPS position on map open |
| **Per-Class Optional** | Classes without a boundary skip geofence check; students only need face verification |

---

## F. AI Face Recognition

| Feature | Detail |
|---|---|
| **Registration** | Selfie captured → multipart POST to `/register-face` with username → embedding stored |
| **Verification** | Live photo → multipart POST to `/login-face` with username → `{"verified": true/false}` |
| **Cold-Start Retry** | 3 attempts, 3/6/9 s backoff, 60 s per-request timeout; user notified on retries |
| **Windows Desktop Workaround** | Opens `camera.html` in browser, then file picker to select the saved photo |
| **On-Device Assist** | `google_mlkit_face_detection` package used client-side for pre-validation |

---

## G. Community / Messaging

| Feature | Detail |
|---|---|
| **Channel Tab** | Class-wide broadcast; all members see all messages; admin messages flagged visually |
| **Direct Message Tab (Student)** | Private thread between student and class admin |
| **Direct Message Tab (Admin)** | List of all students; tap to open each private thread |
| **File Attachments** | File picker selects any file type; uploaded to `community_files` bucket; shown as attachment card |
| **Realtime Delivery** | Appwrite Realtime subscription on `community_messages`; outgoing messages injected locally for zero latency |
| **Timestamps** | Per-message timestamps displayed |

---

## H. Leave Management

| Feature | Detail |
|---|---|
| **Leave Types** | Medical, Casual, Paid Leave, LTC - Tour Leave |
| **Date Range Picker** | Calendar-style start/end date selection |
| **Reason Field** | Up to 500 characters |
| **Hierarchy Routing** | `AdminHierarchyService.resolveApprovers()` finds correct approver for requester's level |
| **Status Tracking** | Pending → Approved / Rejected; status visible to both parties |
| **HR Admin Module** | Dedicated leave tab in HR Admin portal; approve/reject with reason |
| **Leave History** | Full history viewable for each user |
| **CSV / Excel Export** | HR Admin can export leave records |

---

## I. Distribution System

| Feature | Detail |
|---|---|
| **Event CRUD** | Create events with title, description, date, location; draft → active → closed |
| **Recipient Management** | Add individuals or bulk-import from Excel file |
| **Admin Assignment** | Assign specific admins as authorised QR scanners per event |
| **QR Code Generation** | Student's unique QR encodes their username; displayed on "My QR Code" page |
| **QR Scanning (Kiosk)** | `mobile_scanner` camera scan; validates recipient list; marks status as `issued` |
| **Scan Status Outcomes** | success / alreadyIssued / notInList / eventNotActive / notAuthorized / revoked |
| **Scan Log** | Every scan attempt logged in `distribution_scan_logs` with action type |
| **Acknowledgement** | Student taps "Got it" after collection; records `acknowledgedAt`; status → `acknowledged` |
| **Distribution Stats** | Admin sees issued count / total recipients / pending count per event |

---

## J. Admin Portals — General

| Feature | Detail |
|---|---|
| **Animated Tab Transitions** | Slide + fade between tabs (320 ms, easeOutCubic) |
| **Hero Animations** | Class cards use Hero transitions to detail pages |
| **Organisational Chart** | Hierarchical tree built from class assignments; cross-cutting roles shown separately |
| **Student Directory** | Searchable list of all students in department |
| **Registration Approval** | Realtime feed of pending student registrations; one-tap approve/reject |
| **Date-Range Log Filter** | Filter attendance logs by any date range |
| **Class Filter** | Filter logs to a specific class |
| **Multi-Select + Bulk Delete** | Long-press to enter selection mode; delete multiple logs |
| **Soft Delete** | Logs hidden via `isHiddenFromAdmin` without physical deletion |
| **CSV Export (Logs)** | Export filtered attendance logs to CSV |

---

## K. Role-Specific Admin Features

| Role | Unique Features |
|---|---|
| **L1 Institution Admin** | Create classes; assign L2/L3 admins; institution-wide log view; L1 Org Panel |
| **L2 Head of Department** | Department-scoped team view; approve L3 leave; approval requests page |
| **L3 Team Leader** | Class-level management only; run attendance periods |
| **Office Admin** | 6-tab portal: Overview, Students, Reports, Biometrics, Verify, Audit Trail; PDF/CSV/Excel export |
| **HR Admin** | 4-tab portal: Dashboard, Approvals, Leave, Reports; leave data export |
| **Event Admin** | 3-tab portal: Events, Kiosk (QR scanner), Tracking |
| **Security Admin** | 3-tab portal: Audit Logs (searchable), Anomalies (geofence violations), Access Control |
| **Dean (Super Admin)** | 4-tab portal: Personnel (all admins), Distribution, Reports, System Settings; gold UI theme |

---

## L. Reporting & Export

| Format | Available In | Content |
|---|---|---|
| PDF | Office Admin | Formatted attendance summaries per student |
| CSV | Admin (L1), Office Admin, HR Admin | Attendance logs, leave records |
| Excel (XLSX) | Dean, Office Admin, HR Admin, Event Admin | Multi-sheet workbooks |

---

## M. UI/UX

| Feature | Detail |
|---|---|
| **Dark Theme** | Dark backgrounds (`#101010`, `#10121C`) with light card surfaces |
| **Rising Sheet Animation** | Bottom content sheet rises with spring animation on page load |
| **Poppins Typography** | All text uses Google Fonts Poppins |
| **Per-Role Color Accents** | Each admin role has a distinct accent colour in their portal header |
| **Profile Avatars** | `UserAvatar` component: shows Appwrite Storage photo or initials fallback |
| **Skeleton Loaders** | Placeholder shimmer-style grey boxes during data fetch |
