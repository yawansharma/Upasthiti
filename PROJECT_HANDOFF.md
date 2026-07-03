====================================================
PROJECT HANDOFF DOCUMENT
====================================================
Generated: 2026-06-13
Branch: eventhandle2
Last Commit: db50296 — "Added Hierarchy tree visualisation"
====================================================

# 1. Project Overview

## What the Project Does

**Navikarana** (package name: `upasthiti`, meaning "presence" in Sanskrit) is an AI-powered, multi-role attendance management system built with Flutter. It combines face recognition, GPS geofencing, and hierarchical role-based access control (RBAC) to manage attendance across educational institutions (primarily universities/colleges).

## Business Purpose

Replace manual and simple card/biometric attendance systems with a tamper-resistant, multi-layered system that:
- Verifies physical presence using facial recognition and GPS coordinates simultaneously
- Provides a hierarchical chain of command for oversight
- Automates approvals, leave management, and event-based distribution
- Delivers real-time analytics and CSV/Excel export for administration

## Target Users

| Role | Description |
|---|---|
| **Student** | Registers, marks attendance, submits leave requests, views class schedule |
| **Level 3 Admin** | Class-level manager; creates periods, manages one class directly |
| **Level 2 Admin** | Department supervisor; oversees L3 admins and their classes |
| **Level 1 Admin** | Institution-level head; creates classes, assigns L2/L3 staff, views all logs |
| **Office Admin** | Biometrics & records specialist; manages student enrollment, re-enrollment, reports |
| **Dean** | Super admin (hardcoded); full control over all admins, events, supervision mode |

## Core Features

1. **Face-verified attendance** — selfie during check-in matched against enrolled face (Hugging Face ML)
2. **GPS geofencing** — attendance only accepted within configurable radius (30–500 m)
3. **Admin hierarchy** — 3-level admin tree with supervisor/head relationships stored in class metadata
4. **QR event distribution** — Dean creates events, admins scan student QR codes to issue packages
5. **Community messaging** — per-class public channel + student↔admin DMs with file attachments
6. **Leave management** — hierarchical approval chain (level N+1 approves level N)
7. **Student invitations** — admins can invite students directly to classes
8. **Real-time sync** — Appwrite Realtime WebSocket subscriptions everywhere
9. **Data export** — CSV and Excel export for attendance analytics
10. **Org chart visualization** — interactive hierarchy tree for admins

## Current Development Stage

Active feature development on branch `eventhandle2`. The core attendance and admin workflow is functional. Recent work focused on hierarchy visualization, student directory tools, and Office Admin module expansion. There are **26 modified files and 2 untracked new files** not yet committed.

## Major Objectives

- Complete the Office Admin module (OfficeAdminHomePage)
- Finalize student invitation/approval workflow
- Harden security (passwords currently stored plaintext — critical debt)
- Add Office Admin route from admin login flow
- Potentially migrate Dean credentials from hardcoded to database-backed

----------------------------------------------------

# 2. Current Status Summary

## Overall Completion Estimate: ~72%

### Finished Systems
- Student registration (photo, location, face enrollment, pending status)
- Student login + session management
- Class creation, geofence configuration (map picker), period management
- Attendance marking (face + GPS + log creation)
- Community messaging (channel + DM, file attachments, realtime)
- Leave request submission and hierarchical approval
- Admin login (CAPTCHA + level routing)
- Dean login and full personnel management
- QR event distribution system (create, assign admins, scan, audit)
- Admin org chart (hierarchy tree visualization)
- Student directory with invite-to-class functionality
- Approval requests page for pending student registrations
- UserAvatar component with profile picture loading
- App theming system (RisingSheet animations, Poppins fonts)

### Partially Complete
- **Office Admin module** — `OfficeAdminHomePage` exists (`lib/office_admin_home_page.dart`, untracked) with 4 tabs (Overview, Students, Reports, Biometrics), but is **not yet wired into the routing** from `admin_level_select_page.dart`
- **`office_admin_student_attendance_page.dart`** — full implementation exists (untracked) but not routed
- **Student first-login validation** — mentioned in latest commit message, implementation status unclear

### Not Started
- Server-side RBAC (currently all permission checks are client-side)
- Password hashing (currently plaintext in Appwrite documents)
- Push notifications
- PDF report export (only CSV/Excel exists)
- Formal testing suite (only default widget test exists)

### What to Work on Next
1. **Route Office Admin** — wire `OfficeAdminHomePage` into `admin_level_select_page.dart`
2. **Commit all unstaged work** — 26 modified + 2 untracked files
3. **Student first-login validation** — verify if this is complete or still WIP
4. **Security hardening** — at minimum, hash passwords before storing

----------------------------------------------------

# 3. Project Structure

```
d:\GitHub\Navikarana\
├── lib/
│   ├── main.dart                          # Entry point: splash screen, student login, routing
│   ├── app_theme.dart                     # Centralized theme, colors, RisingSheet animation
│   ├── register_page.dart                 # Student self-registration with face + GPS enrollment
│   ├── home_page.dart                     # Student dashboard: classes list, realtime updates
│   ├── class_detail_page.dart             # Attendance marking: face verify + geofence + log
│   ├── profile_page.dart                  # Student profile: password change
│   ├── community_page.dart                # Per-class messaging: channel + DMs
│   ├── admin_login.dart                   # Admin login with CAPTCHA
│   ├── admin_level_select_page.dart       # Routes L1/L2/L3/OfficeAdmin after login ⚠️ NEEDS OFFICE ADMIN ROUTING
│   ├── admin_home_page.dart               # L1/L2/L3 admin dashboard: classes, analytics, settings
│   ├── admin_approval_requests_page.dart  # Lists/approves pending student registrations
│   ├── admin_org_chart_page.dart          # Hierarchy tree visualization for admins
│   ├── admin_hierarchy_views.dart         # L1/L2/L3 sub-panels used in AdminHomePage
│   ├── admin_student_directory_page.dart  # Search all students, invite to class
│   ├── dean_login.dart                    # Hardcoded Dean super-admin login
│   ├── dean_home_page.dart                # Dean dashboard: Personnel, Settings, Distribution, Supervision
│   ├── leave_management_page.dart         # View own/pending leave requests + approve/deny
│   ├── leave_request_page.dart            # Submit new leave request
│   ├── camera_page.dart                   # Windows desktop camera via HTML5 WebView
│   ├── eye_test_dialog.dart               # WebView eye test component
│   ├── office_admin_home_page.dart        # ⚠️ UNTRACKED — Office Admin 4-tab dashboard (Overview/Students/Reports/Biometrics)
│   ├── office_admin_student_attendance_page.dart  # ⚠️ UNTRACKED — Per-student attendance viewer for Office Admin
│   │
│   ├── services/
│   │   ├── appwrite_service.dart          # Appwrite client singleton (endpoint, project ID, collections)
│   │   ├── admin_hierarchy_service.dart   # Hierarchy utilities: parse boundary, resolve assignments, fetch classes
│   │   ├── leave_service.dart             # Leave CRUD (submit, list pending, update status)
│   │   └── distribution_service.dart      # Event/QR distribution: create, scan, audit
│   │
│   ├── components/
│   │   └── user_avatar.dart              # Reusable profile picture widget with Appwrite Storage fallback
│   │
│   └── distribution/
│       ├── user_qr_page.dart             # Student QR code display for event check-in
│       ├── admin_distribution_tab.dart   # Admin event management UI (large — 2000+ lines)
│       ├── admin_scan_page.dart          # Mobile scanner for QR verification
│       └── dean_distribution_tab.dart    # Dean event overview + admin assignment
│
├── assets/
│   ├── upasthiti.png                     # App logo (used in splash, login pages)
│   ├── appLogo.png                       # Windows/iOS launcher icon
│   ├── officeAdmin.md                    # Documentation: Office Admin 15 responsibilities
│   └── otherAdmins.md                    # Documentation: Full admin hierarchy RBAC matrix
│
├── test/
│   └── widget_test.dart                  # Default Flutter widget test (no custom tests)
│
├── android/                              # Android platform config
├── ios/                                  # iOS platform config
├── windows/                              # Windows desktop config
├── web/                                  # Web platform config
├── pubspec.yaml                          # Dependencies, assets, flutter_launcher_icons config
└── PROJECT_HANDOFF.md                    # This file
```

### Important File Notes

| File | Key Responsibility | Dependencies |
|---|---|---|
| `main.dart` | App entry, splash, student login, all routes | All pages via named routes |
| `app_theme.dart` | Single source of colors, text styles, animations | Used by every screen |
| `services/appwrite_service.dart` | Appwrite singleton (database, storage, realtime) | Used by almost every file |
| `services/admin_hierarchy_service.dart` | Decodes boundary JSON, resolves L1/L2/L3 relationships | admin_home_page, admin_org_chart_page |
| `admin_home_page.dart` | Central admin hub with 3 tabs | admin_hierarchy_service, admin_student_directory, admin_org_chart |
| `distribution/admin_distribution_tab.dart` | Largest file (~2016 lines); full event lifecycle UI | distribution_service |
| `office_admin_home_page.dart` | ⚠️ New, untracked, not yet routed | office_admin_student_attendance_page, appwrite_service |

----------------------------------------------------

# 4. Architecture Overview

## High-Level Data Flow

```
Flutter Client (Mobile/Desktop/Web)
         ↓
   Appwrite SDK (v23.1.0)
         ↓
Appwrite Cloud (Singapore: sgp.cloud.appwrite.io)
  ├── Databases (NoSQL collections)
  ├── Storage (profile photos, attendance selfies, community files)
  └── Realtime (WebSocket subscriptions)

                          +
                          ↓
         ML Face Service (Hugging Face Spaces)
         https://pasteshub404-navikarana-backend.hf.space
         ├── POST /register-face   (enrollment during registration)
         └── POST /login-face      (verification during attendance)
```

## Authentication Flow

```
Student:
  LoginPage (main.dart)
    → Query Appwrite users collection (username + plaintext password match)
    → Check role == 'student'
    → Check status == 'active'
    → Navigate to HomePage

Admin:
  AdminLoginPage
    → CAPTCHA challenge (5-char alphanumeric)
    → Query Appwrite users (username + password)
    → Check role == 'admin'
    → Navigate to AdminLevelSelectPage
    → Route to AdminHomePage(level: 1/2/3) OR OfficeAdminHomePage

Dean:
  DeanLoginPage
    → Hardcoded credential check (dean / dean123) ⚠️ SECURITY RISK
    → Navigate to DeanHomePage
```

## Admin Hierarchy Model

```
Level 1 Admin (Institution Head)
  → Creates classes
  → Assigns L2 Admins as supervisors
  → Assigns L3 Admins as heads of class

Level 2 Admin (Department Supervisor)
  → Oversees classes where supervisorId == their username
  → Sees all L3 admins under them
  → Can view aggregate analytics

Level 3 Admin (Class Head)
  → Directly manages assigned classes
  → Creates periods, manages student rolls
  → headAdminId on class == their username

Office Admin
  → Cross-cutting role
  → Manages biometric enrollment, student records, reports
  → Does NOT manage class hierarchy
```

Hierarchy metadata is stored as a JSON blob in `classes.boundary`:
```json
{
  "lat": 18.5204,
  "lng": 73.8567,
  "radiusMeters": 100,
  "headAdminId": "admin_l3_001",
  "headAdminName": "Dr. Sharma",
  "supervisorId": "admin_l2_001",
  "supervisorName": "Prof. Verma"
}
```

## Attendance Marking Flow

```
Student opens ClassDetailPage
  → Check if active period exists (startTime-10min ≤ now ≤ endTime+10min)
  → [If boundary exists] Verify GPS within radiusMeters
  → Open camera → capture selfie
  → POST selfie to /login-face (ML backend)
  → [On success] Upload selfie to Appwrite Storage (attendance_photos bucket)
  → Create attendance_logs document
      { userId, classId, periodId, timestamp, photoUrl,
        isWithinGeofence, isVerified, adminVerifiedStatus: 'Pending',
        entryStatus: 'Early'|'Within Window'|'Late' }
```

## Distribution/QR Event Flow

```
Dean creates event (draft) → adds recipients → assigns admins → activates
Admin opens scan page → scans student QR → service processes:
  ScanStatus: success | alreadyIssued | notInList | eventNotActive | notAuthorized | revoked
  → Increments issuedCount on event
  → Logs to distribution_scan_logs
Student opens user_qr_page → shows QR: {"u": "username", "v": 1}
Dean closes event when complete
```

## State Management

No dedicated state management library (no Provider, Bloc, Riverpod). All state is local `StatefulWidget` state with `setState()`. Realtime subscriptions trigger `setState` callbacks.

## Background Jobs / Queues

None. All operations are synchronous request/response or live Realtime subscriptions.

----------------------------------------------------

# 5. Technologies Used

## Framework & Language
| Technology | Purpose | Version |
|---|---|---|
| Flutter | Cross-platform UI framework | SDK >=3.10.4 |
| Dart | Programming language | ^3.x |

## Backend
| Technology | Purpose | Version/Config |
|---|---|---|
| Appwrite | Backend-as-a-Service (NoSQL DB, Storage, Realtime) | SDK ^23.1.0, Singapore region |
| Hugging Face Spaces | ML face recognition inference (Python backend) | Custom space: pasteshub404-navikarana-backend |

## Key Flutter Packages
| Package | Purpose | Version |
|---|---|---|
| appwrite | Appwrite SDK for Flutter | ^23.1.0 |
| google_mlkit_face_detection | Client-side face detection helper | ^0.11.0 |
| geolocator | GPS location + distance calculation | ^10.1.0 |
| flutter_map | Map widget (OpenStreetMap tiles) for geofence picker | ^8.2.2 |
| latlong2 | Lat/lng coordinate types | ^0.9.1 |
| google_maps_flutter | Google Maps (also imported, may be redundant with flutter_map) | ^2.14.0 |
| camera | Camera hardware access | ^0.11.3 |
| image_picker | Photo from gallery or camera | ^1.0.7 |
| mobile_scanner | QR code scanner | ^5.2.3 |
| qr_flutter | QR code generator | ^4.1.0 |
| webview_flutter | Embedded WebView (eye test, Windows camera) | ^4.13.1 |
| webview_windows | Windows-specific WebView | ^0.4.0 |
| desktop_multi_window | Multi-window support for desktop | ^0.3.0 |
| google_fonts | Poppins font | ^6.2.1 |
| csv | CSV export | ^6.0.0 |
| excel | Excel export | ^4.0.6 |
| file_picker | Cross-platform file picker | ^10.3.8 |
| path_provider | File system paths | ^2.1.5 |
| permission_handler | Runtime permissions | ^12.0.1 |
| intl | Date/time formatting, localization | ^0.19.0 |
| http | HTTP client for ML backend calls | ^1.6.0 |
| url_launcher | Open external URLs | ^6.3.2 |
| location | Alternative location package (also imported) | ^8.0.1 |

## Dev Dependencies
| Package | Purpose |
|---|---|
| flutter_lints | Dart/Flutter linting rules |
| flutter_launcher_icons | Generates app launcher icons for all platforms |

## Infrastructure
- Appwrite Cloud (Singapore region, shared hosting)
- Hugging Face Spaces (free tier — cold start delays possible)
- No custom server infrastructure; fully BaaS

----------------------------------------------------

# 6. Environment Configuration

## Hardcoded Configuration (No .env file — all embedded in code)

### Appwrite
```
Endpoint:   https://sgp.cloud.appwrite.io/v1
Project ID: 6a2c0bd800121a164e77
Database ID: 6a2c10dc000d5e50f314
Profile/File Bucket: 6a2c12a500260c940843
```
**Location:** `lib/services/appwrite_service.dart` (endpoint, projectId, client init) and various page files (databaseId, bucketId constants)

### ML Backend
```
Base URL: https://pasteshub404-navikarana-backend.hf.space
Register endpoint: /register-face
Verify endpoint:   /login-face
```
**Location:** `lib/register_page.dart` (line ~48), `lib/class_detail_page.dart` (line ~73), `lib/office_admin_home_page.dart` (constant `_kFaceBase`)

### Dean Credentials (HARDCODED — CRITICAL RISK)
```
Username: dean
Password: dean123
```
**Location:** `lib/dean_login.dart`

### Important IDs scattered across files
```dart
// In office_admin_home_page.dart
const _kDb = '6a2c10dc000d5e50f314';
const _kProfileBucket = '6a2c12a500260c940843';
const _kFaceBase = 'https://pasteshub404-navikarana-backend.hf.space';

// In admin_hierarchy_service.dart
static const String databaseId = '6a2c10dc000d5e50f314';
```

## Required Permissions
- **Android:** Camera, Location (fine + coarse), Storage, Internet
- **iOS:** Camera, Location When In Use, Photo Library
- **Windows:** Camera (WebView HTML5), file system access

## No .env, No Secrets File
All configuration is hardcoded. There is no `.env` file or secrets management. This is a significant security concern for production deployment.

----------------------------------------------------

# 7. Database Documentation

## Database Type
Appwrite NoSQL (document-based). Not relational — no joins; relationships maintained by storing IDs in arrays.

**Database ID:** `6a2c10dc000d5e50f314`

## Collections

### 1. `users`
**Purpose:** All user accounts (students, admins, dean, office admin)

| Field | Type | Notes |
|---|---|---|
| username | String | Unique identifier (used as login key) |
| name | String | Display name |
| password | String | ⚠️ PLAINTEXT — critical security debt |
| role | String | 'student' \| 'admin' \| 'dean' \| 'officeAdmin' |
| level | Integer | 1, 2, 3 (for admins only) |
| department | String | School/department name |
| status | String | 'pending' \| 'active' \| 'disabled' |
| lastLogin | String | ISO-8601 timestamp |
| latitude | Double | Registered GPS lat (students) |
| longitude | Double | Registered GPS lng (students) |
| profilePictureId | String | Appwrite Storage file ID |
| managedClasses | Array\<String\> | Class doc IDs managed by L3 admin |
| headAdminId | String | (unused top-level; stored in boundary JSON) |
| supervisorId | String | (unused top-level; stored in boundary JSON) |
| createdAt | String | ISO-8601 |
| updatedAt | String | ISO-8601 |

### 2. `classes`
**Purpose:** Class/course records including geofence boundaries and admin assignments

| Field | Type | Notes |
|---|---|---|
| className | String | Display name |
| classCode | String | Short code |
| createdBy | String | L1 admin username |
| adminName | String | Display name of creator |
| adminLevel | Integer | Level of creating admin |
| studentIds | Array\<String\> | Enrolled student usernames |
| boundary | String | JSON blob: `{lat, lng, radiusMeters, headAdminId, headAdminName, supervisorId, supervisorName, pendingStudents[], rejectedStudents[], invitedStudents[]}` |
| headAdminId | String | L3 admin username (mirrored from boundary) |
| headAdminName | String | L3 admin display name (mirrored) |
| supervisorId | String | L2 admin username (mirrored from boundary) |
| supervisorName | String | L2 admin display name (mirrored) |

### 3. `attendance_logs`
**Purpose:** Individual attendance records per student per period

| Field | Type | Notes |
|---|---|---|
| userId | String | Student username |
| classId | String | Class document ID |
| adminId | String | Admin who owns the class |
| periodId | String | Period document ID |
| timestamp | String | ISO-8601 when student submitted |
| photoUrl | String | Appwrite Storage URL of selfie |
| isWithinGeofence | Boolean | Was GPS within boundary |
| isVerified | Boolean | Did face recognition succeed |
| adminVerifiedStatus | String | 'Pending' \| 'Present' \| 'Late' \| 'Absent' |
| entryStatus | String | 'Early' \| 'Within Window' \| 'Late' |

### 4. `periods`
**Purpose:** Scheduled class sessions with time windows

| Field | Type | Notes |
|---|---|---|
| classId | String | Parent class document ID |
| date | String | Date string |
| startTime | String | ISO-8601 start |
| endTime | String | ISO-8601 end |

Attendance valid from `startTime - 10 min` to `endTime + 10 min`.

### 5. `community_messages`
**Purpose:** In-class messaging

| Field | Type | Notes |
|---|---|---|
| classId | String | Parent class |
| channel | String | 'channel' (public) or 'dm_USERNAME' |
| senderId | String | Username of sender |
| text | String | Message body |
| timestamp | String | ISO-8601 |
| isAdmin | Boolean | Whether sender is admin |
| fileUrl | String | Optional attachment URL |
| fileType | String | MIME type |
| fileName | String | Display name |

### 6. `leave_requests`
**Purpose:** Leave application and approval workflow

| Field | Type | Notes |
|---|---|---|
| userId | String | Requester username |
| userName | String | Display name |
| leaveType | String | 'Medical' \| 'Casual' \| 'Paid Leave' \| 'LTC' |
| startDate | String | ISO-8601 date |
| endDate | String | ISO-8601 date |
| reason | String | Free text |
| status | String | 'pending' \| 'approved' \| 'denied' |
| approverLevel | Integer | Admin level required to approve |
| actionBy | String | Username who actioned |
| actionTime | String | ISO-8601 |

### 7. `distribution_events`
**Purpose:** QR-based package distribution events

| Field | Type | Notes |
|---|---|---|
| title | String | Event name |
| description | String | Details |
| scheduledDate | String | ISO-8601 |
| location | String | Venue description |
| status | String | 'draft' \| 'active' \| 'closed' |
| createdBy | String | Dean/admin username |
| issuedCount | Integer | Packages issued so far |
| totalRecipients | Integer | Total eligible recipients |
| createdAt | String | ISO-8601 |

### 8. `event_recipients`
**Purpose:** Per-student event eligibility and issue status

| Field | Type | Notes |
|---|---|---|
| eventId | String | Parent event |
| userId | String | Student username |
| userName | String | Display name |
| status | String | 'pending' \| 'issued' \| 'acknowledged' \| 'revoked' |
| issuedAt | String | ISO-8601 |
| issuedBy | String | Admin who scanned |
| acknowledgedAt | String | ISO-8601 |
| packageNote | String | Optional notes |

### 9. `event_admin_assignments`
**Purpose:** Which admins are authorized to scan for which events

| Field | Type | Notes |
|---|---|---|
| eventId | String | Event reference |
| adminId | String | Admin username |
| adminName | String | Display name |
| assignedBy | String | Dean username |
| assignedAt | String | ISO-8601 |
| isActive | Boolean | Can be deactivated |

### 10. `distribution_scan_logs`
**Purpose:** Immutable audit trail of all QR scan attempts

| Field | Type | Notes |
|---|---|---|
| eventId | String | Event reference |
| scannedUserId | String | Student who was scanned |
| scannedBy | String | Admin who performed scan |
| action | String | 'issued' \| 'duplicate_attempt' \| 'ineligible' \| 'revoked' |
| timestamp | String | ISO-8601 |

## Storage Buckets
| Bucket ID | Purpose |
|---|---|
| `6a2c12a500260c940843` | Profile pictures + biometric re-enrollment images |
| `attendance_photos` | Selfies captured during attendance marking |
| `community_files` | File attachments in class messaging |

## Migrations
No migration tooling. Schema changes are made manually in the Appwrite console. No migration history is tracked in the codebase.

----------------------------------------------------

# 8. API Documentation

The project has no custom REST API layer. All data operations go directly to Appwrite SDK calls. External HTTP calls are only made to the ML face recognition backend.

## ML Backend Endpoints (Hugging Face Spaces)

### POST /register-face
**Purpose:** Enroll a student's face during registration

**Request:** `multipart/form-data`
```
username: <student unique ID>
image:    <binary photo file>
```

**Response (success):**
```json
{ "success": true }
```

**Response (error):**
```json
{ "error": "face not detected" }
```

**Called from:** `lib/register_page.dart`

---

### POST /login-face
**Purpose:** Verify student's face during attendance marking

**Request:** `multipart/form-data`
```
username: <student unique ID>
image:    <binary selfie>
```

**Response (success):**
```json
{ "verified": true }
```

**Response (error):**
```json
{ "error": "face mismatch" }
```

**Called from:** `lib/class_detail_page.dart`, `lib/office_admin_home_page.dart` (biometrics re-enrollment)

---

## Appwrite SDK Usage Patterns

All Appwrite calls follow this pattern. No custom abstraction layer — raw SDK calls in page widgets:

```dart
// Read documents
final result = await AppwriteService.databases.listDocuments(
  databaseId: '6a2c10dc000d5e50f314',
  collectionId: 'attendance_logs',
  queries: [Query.equal('userId', username), Query.limit(50)],
);

// Create document
await AppwriteService.databases.createDocument(
  databaseId: '6a2c10dc000d5e50f314',
  collectionId: 'attendance_logs',
  documentId: ID.unique(),
  data: { ... },
);

// Upload file
await AppwriteService.storage.createFile(
  bucketId: '6a2c12a500260c940843',
  fileId: ID.unique(),
  file: InputFile.fromBytes(bytes: imageBytes, filename: 'photo.jpg'),
);

// Realtime subscription
AppwriteService.realtime.subscribe([
  'databases.6a2c10dc000d5e50f314.collections.classes.documents'
]);
```

----------------------------------------------------

# 9. Features Completed

## 1. Animated Splash Screen
- Files: `lib/main.dart`
- Status: Complete
- Description: 2500ms fade-in, 1100ms fade-out, Poppins branding

## 2. Student Login
- Files: `lib/main.dart` (LoginPage)
- Status: Complete
- Description: Username + password, role check (student only), status check (active only), RBAC error messages, lastLogin update. Easter egg: 5 taps on logo → Dean portal

## 3. Student Registration
- Files: `lib/register_page.dart`
- Status: Complete
- Description: Multi-step wizard — name, unique code, school selection (8 options), password. Photo capture. GPS enrollment. Face enrollment via ML API. Profile picture upload. Status set to 'pending'. Awaits admin approval.

## 4. Admin Login with CAPTCHA
- Files: `lib/admin_login.dart`
- Status: Complete
- Description: Random 5-char alphanumeric CAPTCHA prevents brute force. Level-based routing after success.

## 5. Admin Level Routing
- Files: `lib/admin_level_select_page.dart`
- Status: Mostly complete (Office Admin route missing)
- Description: Visual card selector for L1/L2/L3/Office Admin

## 6. Dean Login (Hardcoded)
- Files: `lib/dean_login.dart`
- Status: Complete (but insecure)
- Known Limitation: Hardcoded credentials dean/dean123

## 7. Student Dashboard (HomePage)
- Files: `lib/home_page.dart`
- Status: Complete
- Description: Lists classes by status (joined/pending/rejected/invited/explore). Realtime updates. New acceptance notification. Hero animations on navigation.

## 8. Attendance Marking
- Files: `lib/class_detail_page.dart`
- Status: Complete
- Description: Active period detection, geofence check, camera selfie, ML face verification, Appwrite log creation, history display with entry status.

## 9. Community Messaging
- Files: `lib/community_page.dart`
- Status: Complete
- Description: Channel (public) + DMs. File attachments. Realtime sync. Admin message highlighting.

## 10. Leave Request System
- Files: `lib/leave_request_page.dart`, `lib/leave_management_page.dart`, `lib/services/leave_service.dart`
- Status: Complete
- Description: Submit, view own, approve/deny. Hierarchical approval levels.

## 11. Admin Dashboard (L1/L2/L3)
- Files: `lib/admin_home_page.dart`, `lib/admin_hierarchy_views.dart`
- Status: Complete
- Description: 3-tab UI. Classes (create/edit/delete/geofence/enroll). Analytics (logs, filters, CSV export, batch delete). Settings (approvals, directory, org chart).

## 12. Student Approval Workflow
- Files: `lib/admin_approval_requests_page.dart`
- Status: Complete (latest commit)
- Description: Lists pending registrations, allows approve/reject with department filtering.

## 13. Org Chart Visualization
- Files: `lib/admin_org_chart_page.dart`
- Status: Complete (latest commit)
- Description: Builds tree of OrgNode objects from all admins + class assignments. Shows head/supervisor relationships.

## 14. Student Directory & Invites
- Files: `lib/admin_student_directory_page.dart`
- Status: Complete (latest commit)
- Description: Search all active students, filter by department, invite to any class.

## 15. Admin Hierarchy Service
- Files: `lib/services/admin_hierarchy_service.dart`
- Status: Complete
- Description: Parse boundary JSON, resolve L1/L2/L3 chains, persist assignments, fetch classes per level.

## 16. Dean Personnel Management
- Files: `lib/dean_home_page.dart`
- Status: Complete
- Description: Create admins, override passwords, suspend/reactivate accounts.

## 17. QR Distribution System
- Files: `lib/distribution/`, `lib/services/distribution_service.dart`
- Status: Complete
- Description: Full event lifecycle from draft to closed. QR scanning with status tracking. Audit logs. Admin assignment.

## 18. UserAvatar Component
- Files: `lib/components/user_avatar.dart`
- Status: Complete (latest commit)
- Description: Reusable profile picture with Appwrite Storage loading and fallback initials.

## 19. Windows Camera Support
- Files: `lib/camera_page.dart`
- Status: Complete
- Description: HTML5 getUserMedia via WebView for Windows desktop camera capture.

## 20. App Theming System
- Files: `lib/app_theme.dart`
- Status: Complete
- Description: RisingSheet animation, Poppins fonts, green/dark color palette, consistent input decorations.

----------------------------------------------------

# 10. Features In Progress

## 1. Office Admin Home Page
**Current State:** File exists (`lib/office_admin_home_page.dart`, untracked) with full 4-tab implementation

**What's Done:**
- `_OverviewTab` — attendance stats for the department
- `_StudentsTab` — student list with search, profile pictures
- `_ReportsTab` — date-filtered attendance reports, CSV/Excel export
- `_BiometricsTab` — re-enrollment workflow using ML backend

**What's Missing:**
- Route from `admin_level_select_page.dart` for 'officeAdmin' role
- File needs to be committed
- Integration testing

**Files Involved:**
- `lib/office_admin_home_page.dart` (untracked)
- `lib/admin_level_select_page.dart` (needs routing added)
- `lib/office_admin_student_attendance_page.dart` (untracked, used by OfficeAdminHomePage)

**Recommended Next Steps:**
1. Add `import 'office_admin_home_page.dart'` to `admin_level_select_page.dart`
2. In the level select tap handler, when `role == 'officeAdmin'`, navigate to `OfficeAdminHomePage`
3. Commit both new files
4. Test the full Office Admin flow

## 2. Student First-Login Validation
**Current State:** Mentioned in latest commit message ("Student validation for first login") but implementation details unclear from code inspection

**What's Missing:**
- Exact validation logic needs verification
- Unknown if it's wired up or only partially implemented

**Files Involved:** Likely `lib/main.dart` or `lib/register_page.dart`

**Recommended Next Steps:**
- Grep for first-login or validation logic to determine current state
- Verify the registration-to-first-login flow end-to-end

----------------------------------------------------

# 11. Current Task

## Latest Commit Summary (db50296)
"Added Hierarchy tree visualisation, full list of students visible to L2 and L3, Student validation for first login, student invitations to classes available"

## Active Work (Uncommitted)
The git status shows **26 modified files and 2 new untracked files**. This represents substantial work done since the last commit that has NOT been saved to git yet.

### New Untracked Files (must be committed):
1. `lib/office_admin_home_page.dart` — Full Office Admin dashboard
2. `lib/office_admin_student_attendance_page.dart` — Per-student attendance viewer

### Modified Files (staged for next commit):
All major lib files are modified: admin pages, home page, register page, main.dart, distribution system, services.

## Immediate Current Objective
The most likely current task based on the work context:
**Wire the Office Admin role into the admin routing flow and commit all pending work.**

## Files Being Modified
- `lib/admin_level_select_page.dart` — needs Office Admin navigation case
- `lib/office_admin_home_page.dart` — new, needs commit
- `lib/office_admin_student_attendance_page.dart` — new, needs commit

## Decisions Already Made
- Office Admin has its own separate homepage (not AdminHomePage)
- Office Admin accent color is `Color(0xFF8A6A6A)` (muted rose/brick)
- Office Admin has 4 tabs: Overview, Students, Reports, Biometrics
- Student attendance viewer is a separate routed page within the Office Admin flow

## Remaining Work
1. Connect Office Admin route in `admin_level_select_page.dart`
2. Verify first-login validation logic is complete
3. Commit all 26 modified + 2 new untracked files
4. Test Office Admin end-to-end on device/emulator

----------------------------------------------------

# 12. Open Bugs and Issues

### Priority: CRITICAL

**Issue 1: Plaintext Password Storage**
- Description: All user passwords stored as plaintext strings in Appwrite documents
- Root Cause: No hashing implemented during registration or admin creation
- Affected Files: `lib/register_page.dart`, `lib/admin_login.dart`, `lib/dean_home_page.dart`, `lib/main.dart`
- Recommended Fix: Hash with bcrypt or SHA-256 before storing; validate hash on login
- Impact: Complete credential exposure if Appwrite data is ever accessed by unauthorized party

**Issue 2: Hardcoded Dean Credentials**
- Description: `dean / dean123` hardcoded in `lib/dean_login.dart`
- Root Cause: No database-backed dean authentication
- Affected Files: `lib/dean_login.dart`
- Recommended Fix: Move dean account to `users` collection with hashed password, role='dean'

**Issue 3: Client-Side RBAC**
- Description: All permission checks happen in Flutter client code; Appwrite collections have no server-side document security rules
- Root Cause: Appwrite document security not configured
- Affected Files: All page files
- Recommended Fix: Configure Appwrite collection-level permissions; use Appwrite server-side functions for sensitive operations

---

### Priority: HIGH

**Issue 4: Office Admin Not Routed**
- Description: `OfficeAdminHomePage` exists but `admin_level_select_page.dart` doesn't navigate to it
- Root Cause: File is untracked; routing not added yet
- Affected Files: `lib/admin_level_select_page.dart`, `lib/office_admin_home_page.dart`
- Recommended Fix: Add navigation case for officeAdmin role (see Section 10)

**Issue 5: Hardcoded Appwrite IDs Throughout Files**
- Description: Database ID, bucket ID, and project ID duplicated across many files (not centralized)
- Root Cause: No constants file; IDs copied directly into each widget
- Affected Files: Multiple — at least `office_admin_home_page.dart`, `admin_hierarchy_service.dart`, `admin_org_chart_page.dart`, etc.
- Recommended Fix: Centralize all IDs in `AppwriteService` as static constants

**Issue 6: Uncommitted Work**
- Description: 26 modified + 2 untracked files represent significant work not saved to git
- Root Cause: Pending final wire-up of Office Admin routing before committing
- Recommended Fix: Complete routing, commit all changes, push to remote

---

### Priority: MEDIUM

**Issue 7: Cold Start Delays on ML Backend**
- Description: Hugging Face Spaces free tier sleeps after inactivity; face recognition may fail with timeout on first call
- Root Cause: Free tier infrastructure limitations
- Affected Files: `lib/register_page.dart`, `lib/class_detail_page.dart`
- Recommended Fix: Add retry logic with user-friendly "warming up, please wait" UI

**Issue 8: Query Limit of 100/200 Not Paginated**
- Description: All Appwrite listDocuments calls use fixed limits (100, 200, 500); no pagination
- Root Cause: Simplicity; likely fine for small institutions
- Affected Files: `lib/services/admin_hierarchy_service.dart`, multiple page files
- Recommended Fix: Add cursor-based pagination for scalability

**Issue 9: Duplicate Location Packages**
- Description: Both `location: ^8.0.1` and `geolocator: ^10.1.0` are in pubspec; both do similar things
- Root Cause: Possibly added at different stages without cleanup
- Affected Files: `pubspec.yaml`
- Recommended Fix: Standardize on geolocator; remove location package

---

### Priority: LOW

**Issue 10: No Loading State on Face Registration at ML Backend**
- Description: If ML backend is slow/down during registration, UX is poor
- Recommended Fix: Add loading overlay and timeout handling

**Issue 11: No Input Validation on Several Forms**
- Description: Leave request, community messages lack input length validation
- Recommended Fix: Add max-length constraints and sanitization

----------------------------------------------------

# 13. Technical Debt

## 1. Plaintext Passwords (Critical)
All passwords stored unencrypted. See Issue 1 above. Estimated fix: 2–3 hours.

## 2. No Constants File
Database ID `6a2c10dc000d5e50f314` and bucket IDs appear in at least 8 files. Any change to backend requires hunting all occurrences. Should be centralized in `AppwriteService` or a dedicated `constants.dart`.

## 3. No Error Boundary / Global Error Handler
Network failures and Appwrite exceptions are caught locally in each widget with varying degrees of user feedback. No consistent error handling pattern.

## 4. Admin Distribution Tab (2000+ lines)
`lib/distribution/admin_distribution_tab.dart` is extremely long. Should be refactored into sub-widgets or separate pages.

## 5. Duplicate Map Packages
Both `flutter_map` and `google_maps_flutter` are dependencies. The geofence picker appears to use `flutter_map` (OpenStreetMap). `google_maps_flutter` may be unused — removing it would reduce app size.

## 6. Duplicate Location Packages
`location` and `geolocator` both installed (see Issue 9).

## 7. No Service Layer Abstraction for Pages
Business logic (Appwrite queries, data transformation) is embedded directly in widget `State` classes. Should be extracted to service classes or repositories for testability.

## 8. No Automated Tests
Only the default Flutter widget test exists. Zero coverage of core business logic (face verification flow, geofence check, attendance creation).

## 9. `office_admin_home_page.dart` Constants Duplication
The new Office Admin page re-defines `_kDb`, `_kProfileBucket`, and `_kFaceBase` as local constants instead of using `AppwriteService`.

## 10. Appwrite Free Tier Limits
As user count grows, free tier Appwrite quotas (requests/day, storage limits) may become a constraint. No monitoring is in place.

----------------------------------------------------

# 14. Important Decisions Made

**Decision 1: Appwrite as Full Backend**
- Reason: Rapid development; no need to write custom server code; realtime built-in
- Alternatives Considered: Firebase, custom Node.js/FastAPI
- Impact: Vendor lock-in; all data queries shaped around Appwrite SDK; no SQL

**Decision 2: Face Recognition on Hugging Face Spaces**
- Reason: Free ML inference hosting; no GPU server required
- Alternatives Considered: On-device ML only (google_mlkit), paid cloud API
- Impact: Cold start delays; dependency on external service; no SLA

**Decision 3: Hierarchy Stored in Class Boundary JSON**
- Reason: Appwrite collections had limited attribute slots; boundary JSON was already a string field that could accommodate additional data
- Alternatives Considered: Separate collection for assignments, top-level fields on class
- Impact: Boundary JSON parsing must always handle assignment keys; `AdminHierarchyService.parseBoundaryRaw()` is the canonical decoder

**Decision 4: No State Management Library**
- Reason: Project scope; local state with setState() sufficient for current complexity
- Alternatives Considered: Provider, Riverpod, Bloc
- Impact: Rebuilds can be inefficient; harder to share state across distant widgets

**Decision 5: CAPTCHA on Admin Login Only**
- Reason: Students are known individuals (registration approved); admin accounts are higher-value targets
- Alternatives Considered: CAPTCHA on all logins, rate limiting
- Impact: Student login has no brute-force protection

**Decision 6: Office Admin as Separate Role from L1/L2/L3**
- Reason: Office Admin has different responsibilities (biometrics, records) vs. hierarchy management
- Alternatives Considered: Office Admin as L4 or special L1
- Impact: Requires separate routing and homepage; `role == 'officeAdmin'` distinct from `role == 'admin'`

**Decision 7: Dean Login Hardcoded**
- Reason: Single dean instance; quick implementation
- Alternatives Considered: Database-backed dean with special role
- Impact: Credentials exposed in source code; cannot change without app update

----------------------------------------------------

# 15. Recent Changes

## This Session / Branch `eventhandle2`

### Latest Commit: db50296 — "Added Hierarchy tree visualisation"
**Files Changed:** 14 files, +1931 insertions, -443 deletions

**Features Added:**
- `lib/admin_org_chart_page.dart` — New: Full org chart with OrgNode tree built from all admin docs + class assignments. Visualizes L1→L2→L3 chains with UserAvatar profile pics.
- `lib/admin_approval_requests_page.dart` — New: Lists all pending student registrations. Approve/reject with department filter.
- `lib/admin_student_directory_page.dart` — New: Full student directory with search, department filter, invite-to-class functionality.
- `lib/components/user_avatar.dart` — New: Reusable avatar widget loading from Appwrite Storage with initials fallback.
- `lib/home_page.dart` — Major additions: Student invitation acceptance flow, new class status tracking, improved realtime handling, first-login validation.
- `lib/register_page.dart` — Major refactor: Improved UI, better error handling, multi-step flow refinements.
- `lib/main.dart` — Major refactor: Routing updates, splash improvements.

### Previous Commit: cb7dd14 — "Event Handling - Allowed Level 1 admins to create events"
**Features Added:**
- L1 admins can now create distribution events (previously Dean-only)
- `admin_distribution_tab.dart` major expansion

### Previous Commit: e29d61c — "added list of students"
- L2/L3 admins can view list of students in their classes
- Student visibility scoped to hierarchy level

### Uncommitted Work (Current)
**New Files (untracked):**
- `lib/office_admin_home_page.dart` — Full Office Admin dashboard with 4 tabs
- `lib/office_admin_student_attendance_page.dart` — Per-student attendance detail viewer

**Modified Files (all major lib files updated but not committed):**
Many files have additional uncommitted refinements beyond the last commit.

----------------------------------------------------

# 16. Important Commands

## Setup & Installation

```bash
# Install Flutter dependencies
flutter pub get

# Generate launcher icons (after icon changes)
flutter pub run flutter_launcher_icons

# Check Flutter environment
flutter doctor
```

## Development

```bash
# Run on connected Android device or emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows

# Run with verbose logging
flutter run -v

# Hot reload (press 'r' in terminal while running)
# Hot restart (press 'R' in terminal while running)
```

## Build

```bash
# Android APK (debug)
flutter build apk --debug

# Android APK (release)
flutter build apk --release

# Android App Bundle
flutter build appbundle

# iOS (requires macOS + Xcode)
flutter build ios

# Windows Desktop
flutter build windows

# Web
flutter build web
```

## Analysis & Testing

```bash
# Analyze code for linting errors
flutter analyze

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Git (Current Branch State)

```bash
# Check current status
git status

# View recent history
git log --oneline -10

# Add and commit all pending work
git add lib/office_admin_home_page.dart lib/office_admin_student_attendance_page.dart assets/officeAdmin.md assets/otherAdmins.md
git add lib/
git commit -m "Wire Office Admin routing and add Office Admin dashboard"

# Push to remote
git push origin eventhandle2

# Compare with main
git diff main..eventhandle2 --stat
```

----------------------------------------------------

# 17. Testing Status

## Automated Tests
**Existing:** Only `test/widget_test.dart` (default Flutter test — tests that the app widget tree pumps without error)

**Coverage:** Essentially 0% of business logic is covered.

**Missing Tests (high priority):**
- Face recognition integration (mock ML backend)
- Geofence distance calculation
- Attendance log creation logic
- Admin hierarchy resolution (L1/L2/L3 class fetching)
- Leave approval chain
- QR scan state machine (ScanStatus enum)
- Distribution service atomic operations

## Manual Testing Completed (inferred from commits)
- Student registration flow (photo, GPS, face enrollment)
- Admin login with CAPTCHA
- Class creation with geofence map picker
- Attendance marking (face + GPS)
- Community messaging (channel + DM)
- Leave submission and approval
- Dean personnel management
- QR distribution event flow
- Org chart rendering
- Student directory and invite flow
- Approval requests

## Known Failing Areas (untested)
- Office Admin home page (new, unrouted — not yet tested end-to-end)
- Windows camera fallback (limited testing)
- Cold start of Hugging Face ML backend (timeout behavior not formally tested)
- Large datasets (>100 users, >200 classes — query limit behavior)

----------------------------------------------------

# 18. Relevant File Paths

```
Authentication (Student):
  lib/main.dart → LoginPage class

Authentication (Admin):
  lib/admin_login.dart → AdminLoginPage

Authentication (Dean):
  lib/dean_login.dart → DeanLoginPage

Level Routing:
  lib/admin_level_select_page.dart → AdminLevelSelectPage

Student Dashboard:
  lib/home_page.dart → HomePage

Attendance Marking:
  lib/class_detail_page.dart → ClassDetailPage

Admin Dashboard:
  lib/admin_home_page.dart → AdminHomePage

Office Admin Dashboard (NEW, untracked):
  lib/office_admin_home_page.dart → OfficeAdminHomePage

Dean Dashboard:
  lib/dean_home_page.dart → DeanHomePage

Org Chart:
  lib/admin_org_chart_page.dart → AdminOrgChartPage

Student Approvals:
  lib/admin_approval_requests_page.dart → AdminApprovalRequestsPage

Student Directory:
  lib/admin_student_directory_page.dart → AdminStudentDirectoryPage

Office Admin Student Detail (NEW, untracked):
  lib/office_admin_student_attendance_page.dart → OfficeAdminStudentAttendancePage

Community Messaging:
  lib/community_page.dart → CommunityPage

Leave System:
  lib/leave_request_page.dart → LeaveRequestPage
  lib/leave_management_page.dart → LeaveManagementPage
  lib/services/leave_service.dart → LeaveService

Distribution/QR:
  lib/distribution/admin_distribution_tab.dart → AdminDistributionTab
  lib/distribution/admin_scan_page.dart → AdminScanPage
  lib/distribution/user_qr_page.dart → UserQrPage
  lib/distribution/dean_distribution_tab.dart → DeanDistributionTab
  lib/services/distribution_service.dart → DistributionService

Hierarchy Utilities:
  lib/services/admin_hierarchy_service.dart → AdminHierarchyService, ClassAssignments

Appwrite Client:
  lib/services/appwrite_service.dart → AppwriteService

Theme System:
  lib/app_theme.dart → AppTheme, RisingSheet

Shared Component:
  lib/components/user_avatar.dart → UserAvatar

Dependencies:
  pubspec.yaml

Admin Role Documentation:
  assets/officeAdmin.md
  assets/otherAdmins.md
```

----------------------------------------------------

# 19. Known Risks

## Stability Risks
- **Cold start on ML backend:** Hugging Face free Spaces sleep after inactivity. Face registration/verification can timeout on first call after idle period. Students may see errors and think registration failed.
- **No retry logic:** HTTP calls to ML backend have no automatic retry. A single timeout = user sees error.
- **Realtime subscription leaks:** If `dispose()` isn't called properly on Appwrite Realtime subscriptions, memory leaks and stale updates may occur.
- **Hard limits on Appwrite queries:** All lists use fixed `Query.limit(100-500)`. If collections grow larger, silent data truncation occurs.

## Deployment Risks
- **Uncommitted work:** 26 modified + 2 untracked files. If the machine is lost or disk corrupted before committing, this work is gone.
- **No CI/CD pipeline:** No automated build or test on push. Broken code can reach main branch undetected.
- **Appwrite free tier limits:** Request quotas, storage limits, and function invocation counts may be hit as usage grows.

## Security Risks
- **Plaintext passwords:** Critical. Anyone with Appwrite console access or a compromised API key can read all user passwords.
- **Hardcoded Dean credentials:** `dean/dean123` is in source code; anyone with repo access can log in as super admin.
- **No server-side authorization:** Appwrite collections lack document-level security rules. Any client with the project ID could potentially query any collection.
- **Appwrite Project ID in source:** The project ID `69ecea2600127cefd5b2` is publicly visible in source code. Combined with misconfigured collection permissions, this is exploitable.
- **Face spoofing:** ML backend relies on photo matching; sophisticated photo attacks (deepfake, printed photo) may bypass verification.
- **GPS spoofing:** Geofence uses device-reported GPS. Mock GPS apps on rooted Android devices can spoof location.

## Performance Risks
- **admin_distribution_tab.dart is 2000+ lines:** Likely causes long build times and high memory usage on low-end devices.
- **No image compression:** Profile photos and attendance selfies uploaded at full resolution. Storage costs grow quickly.
- **Org chart with 500 admin query:** `Query.limit(500)` on users collection during org chart fetch may be slow for large institutions.

## Scalability Risks
- **Flat collection queries:** No server-side aggregation; all analytics computed client-side from fetched logs.
- **No caching layer:** Every page navigation refetches all data from Appwrite.

----------------------------------------------------

# 20. Next Session Startup Instructions

## Step 1: Orient Yourself (Read These Files First)
1. `lib/services/appwrite_service.dart` — understand the backend configuration
2. `lib/services/admin_hierarchy_service.dart` — understand how L1/L2/L3 relationships work
3. `lib/admin_level_select_page.dart` — understand the routing entry point that needs Office Admin wiring
4. `lib/office_admin_home_page.dart` — understand what the new Office Admin dashboard does
5. `lib/app_theme.dart` — understand the design system before touching any UI

## Step 2: Verify Current State
```bash
git status             # Confirm 26 modified + 2 untracked files
git log --oneline -5   # Confirm you're on eventhandle2 branch
flutter doctor         # Confirm environment is healthy
```

## Step 3: Complete the Office Admin Routing
In `lib/admin_level_select_page.dart`, add the navigation case for Office Admin:
- Find where the level select buttons navigate to `AdminHomePage`
- Add a condition: if admin role is `officeAdmin`, navigate to `OfficeAdminHomePage` instead
- Import `office_admin_home_page.dart`
- Pass `adminName`, `adminId`, `adminDepartment` from the login data

## Step 4: Commit All Pending Work
```bash
git add lib/office_admin_home_page.dart
git add lib/office_admin_student_attendance_page.dart
git add assets/officeAdmin.md assets/otherAdmins.md
git add lib/
git status  # verify staging
git commit -m "Add Office Admin dashboard, student directory, org chart, approval workflow"
git push origin eventhandle2
```

## Step 5: Test Office Admin End-to-End
1. Create a test user with `role: 'officeAdmin'` in Appwrite console
2. Log in via Admin Login → select Office Admin level
3. Verify all 4 tabs (Overview, Students, Reports, Biometrics) load correctly
4. Test student drill-down into `OfficeAdminStudentAttendancePage`

## Step 6: Verify These Areas After Changes
- Admin login → Office Admin routing path (new)
- Student registration → pending status → admin approval flow
- L1 Admin class creation with L2/L3 assignment
- Attendance marking (face + GPS) still functional
- Community messaging still functional

## Step 7: Known Pitfalls to Avoid
- Do NOT modify `boundary` field directly without using `AdminHierarchyService.encodeBoundaryWithAssignments()` — it will lose assignment data
- Do NOT add new Appwrite database/bucket IDs without also adding them to `AppwriteService` as constants
- Do NOT test Dean login with wrong credentials — account is locked to `dean/dean123` hardcoded in `dean_login.dart`
- The ML backend at Hugging Face may be sleeping — give it 30–60 seconds to warm up on first face verification attempt
- When adding new Appwrite queries, always include `Query.limit()` explicitly — default limit may be very low

## Concrete Continuation Plan
1. Open `lib/admin_level_select_page.dart` and add Office Admin route (30 min)
2. Run app, test Office Admin login flow (20 min)
3. Fix any issues found during testing (variable time)
4. Commit all work with descriptive message (10 min)
5. Address Security Issue #1 (password hashing) — high priority for production readiness (2–3 hours)

----------------------------------------------------

# 21. Executive Summary For New Claude

## What This Project Is
**Navikarana/Upasthiti** is a Flutter-based AI attendance management system for educational institutions. It uses face recognition (Hugging Face ML backend) and GPS geofencing to verify student presence. It has a 4-level admin hierarchy (Dean → L1 → L2 → L3 + Office Admin), with each level having different visibility and management capabilities. The backend is Appwrite (NoSQL, Singapore cloud). The current development branch is `eventhandle2`.

## Current Status (~72% Complete)
The core attendance, messaging, leave management, and admin hierarchy systems are working. The most recently completed work added org chart visualization, student directory/invite tools, and the Office Admin dashboard module. **The Office Admin page is fully built but not yet wired into routing** — this is the immediate blocking task.

## Current Task
Wire `OfficeAdminHomePage` (in `lib/office_admin_home_page.dart`, currently untracked) into `lib/admin_level_select_page.dart`. Then commit the ~26 modified + 2 new files to git.

## Most Important Files
| File | Why It Matters |
|---|---|
| `lib/services/appwrite_service.dart` | All backend config (endpoint, projectId, databaseId) |
| `lib/services/admin_hierarchy_service.dart` | How the L1/L2/L3 hierarchy is decoded and maintained |
| `lib/admin_level_select_page.dart` | **Needs Office Admin routing added** |
| `lib/office_admin_home_page.dart` | New 4-tab dashboard (untracked, ready to wire) |
| `lib/admin_home_page.dart` | Central L1/L2/L3 admin interface |
| `lib/main.dart` | Student login + all named routes |
| `lib/app_theme.dart` | Design system; RisingSheet animations; Poppins fonts |

## Biggest Risks
1. **Security:** Passwords are plaintext in Appwrite; Dean credentials hardcoded (`dean/dean123`) — NOT production-ready
2. **Uncommitted work:** 26 modified + 2 untracked files; must be committed before any session ends
3. **ML cold starts:** Hugging Face free tier sleeps; face recognition may timeout on first call
4. **No tests:** Zero automated test coverage on business logic

## Immediate Next Actions
1. Open `lib/admin_level_select_page.dart` → add Office Admin navigation branch
2. Import and route to `OfficeAdminHomePage` with `adminName`, `adminId`, `adminDepartment` params
3. Test the Office Admin login path manually
4. Commit: `git add lib/ assets/ && git commit -m "Wire Office Admin routing"`
5. Push: `git push origin eventhandle2`
6. Next priority: hash passwords before storing (security debt)

====================================================
END OF HANDOFF
====================================================
