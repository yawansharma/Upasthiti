<div align="center">
  <h1>upasthiti</h1>
  <p><strong>Secure, Smart, Verified.</strong></p>
  <p>A cross-platform intelligent attendance and institutional management platform by <strong>Navonmesh Samadhan LLP</strong></p>
</div>

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Architecture](#architecture)
4. [User Roles & Access Control](#user-roles--access-control)
5. [Feature Documentation](#feature-documentation)
   - [Authentication & Account Management](#1-authentication--account-management)
   - [Student / Employee Portal](#2-student--employee-portal)
   - [Attendance System](#3-attendance-system)
   - [Geofencing](#4-geofencing)
   - [AI-Powered Face Recognition](#5-ai-powered-face-recognition)
   - [Community (Messaging)](#6-community-messaging)
   - [Leave Management System](#7-leave-management-system)
   - [Distribution System](#8-distribution-system)
   - [Institution Admin Portal (Level 1)](#9-institution-admin-portal-level-1)
   - [Head of Department Portal (Level 2)](#10-head-of-department-portal-level-2)
   - [Team Leader Portal (Level 3)](#11-team-leader-portal-level-3)
   - [Office Admin Portal](#12-office-admin-portal)
   - [HR Admin Portal](#13-hr-admin-portal)
   - [Event Admin Portal](#14-event-admin-portal)
   - [Security Admin Portal](#15-security-admin-portal)
   - [Super Admin Portal (Dean)](#16-super-admin-portal-dean)
   - [Organizational Chart](#17-organizational-chart)
   - [Student Registration Approval Workflow](#18-student-registration-approval-workflow)
6. [Security & Data Privacy](#security--data-privacy)
7. [Realtime Capabilities](#realtime-capabilities)
8. [Export & Reporting](#export--reporting)
9. [Dependencies & Libraries](#dependencies--libraries)

---

## Overview

**upasthiti** is a comprehensive, multi-role institutional management platform built with Flutter. It is designed to manage attendance, leave, resource distribution, and institutional operations for organizations of any size. The system combines GPS-based geofencing, AI-driven facial recognition, and a real-time cloud database to deliver a secure, verified, and fully auditable attendance ecosystem.

The product is structured around a strict **Role-Based Access Control (RBAC)** model, supporting six distinct administrator types operating at different levels of the institutional hierarchy, in addition to the end-user (employee/student) layer.

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend** | Flutter (Dart) | Cross-platform mobile & desktop UI |
| **Backend-as-a-Service** | Appwrite Cloud (Singapore region) | Database, Storage, Realtime, Auth |
| **ML Inference** | Hugging Face Spaces (Python) | AI Face Recognition API |
| **Database** | Appwrite NoSQL | Document-based storage |
| **Realtime** | Appwrite Realtime (WebSocket) | Live attendance and message updates |
| **Cryptography** | SHA-256 (via `crypto` package) | Password hashing |
| **Maps** | `flutter_map` + `latlong2` | Interactive geofence map display |
| **QR Codes** | `qr_flutter` + `mobile_scanner` | Distribution event scanning |
| **PDF Export** | `pdf` + `printing` | Attendance report generation |
| **Excel Export** | `excel` | Bulk data export |
| **CSV Export** | `csv` | Comma-separated data export |
| **Typography** | Google Fonts (Poppins) | Consistent brand typography |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Flutter Application                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Student UI  │  │   Admin UIs  │  │  Dean UI     │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └─────────────────┴─────────────────┘          │
│                           │                             │
│              ┌────────────▼───────────┐                 │
│              │    AppwriteService     │                 │
│              │  (Singleton SDK Layer) │                 │
│              └────────────┬───────────┘                │
└───────────────────────────┼─────────────────────────────┘
                            │
          ┌─────────────────┼──────────────────┐
          ▼                 ▼                  ▼
  ┌───────────────┐ ┌───────────────┐ ┌───────────────────┐
  │ Appwrite DB   │ │Appwrite       │ │  Hugging Face     │
  │ (NoSQL Docs)  │ │Storage Buckets│ │  ML Backend       │
  │               │ │               │ │  /register-face   │
  │ Collections:  │ │ Buckets:      │ │  /login-face      │
  │ - users       │ │ - profiles    │ │                   │
  │ - classes     │ │ - attendance_ │ └───────────────────┘
  │ - attendance_ │ │   photos      │
  │   logs        │ │ - community_  │
  │ - community_  │ │   files       │
  │   messages    │ │               │
  │ - leave_      │ └───────────────┘
  │   requests    │
  │ - distribution│
  │   _events     │
  │ - event_      │
  │   recipients  │
  └───────────────┘
```

The application talks to a **single Appwrite project** running on the Singapore cloud region. The `AppwriteService` class (a Dart static singleton) initialises one `Client`, `Databases`, `Storage`, and `Realtime` instance that are shared by every screen in the app. Face recognition is handled by a separately hosted **Python microservice on Hugging Face Spaces**, contacted via HTTP multipart form requests.

---

## User Roles & Access Control

upasthiti enforces **strict role-based access control at every layer** — from the login screen through to individual database queries. Eight distinct roles exist in the system:

| Role Token | Display Name | Access Portal |
|---|---|---|
| `student` | Employee / Student | Employee Portal |
| `admin` (level 1) | Institution Admin | Level 1 Admin Portal |
| `admin` (level 2) | Head of Department | Level 2 Admin Portal |
| `admin` (level 3) | Team Leader | Level 3 Admin Portal |
| `officeAdmin` | Office Admin | Office Admin Portal |
| `eventAdmin` | Event Admin | Event Admin Portal |
| `hrAdmin` | HR Admin | HR Admin Portal |
| `securityAdmin` | Security Admin | Security Admin Portal |
| `dean` | Super Admin | Dean / Executive Portal |

- Employees log in via the standard login screen.
- Admins (levels 1–3, Office, Event, HR, Security) log in via a **separate Admin Portal** accessible from the login screen's "ADMIN" button.
- The **Super Admin (Dean) portal** is hidden behind a **secret gesture**: tapping the app logo five times in rapid succession on the login screen reveals a "Super Admin Portal" button. This button is invisible to ordinary users.

---

## Feature Documentation

### 1. Authentication & Account Management

#### Animated Splash Screen
Upon launch, the app displays an animated splash screen showing the upasthiti logo. The logo **fades and scales in** over 1.5 seconds using a `CurvedAnimation` with an `easeOutBack` curve, then **fades and scales out** over 1 second before transitioning to the login page via a smooth 800ms fade transition.

#### Employee / Student Login
- Users log in using their **Unique ID (username)** and password.
- Login queries the Appwrite `users` collection by `username` field.
- **Dual-mode password verification**: The system supports both plaintext (legacy) and SHA-256-hashed passwords simultaneously. On every successful login with a plaintext password, the system silently upgrades it to a hashed value in the database, enabling seamless migration to hashed credentials without any downtime or user intervention.
- A **`lastLogin` timestamp** is recorded on every successful login.
- **RBAC enforcement**: If the user's role is `admin` or `dean`, the standard login is rejected with "Unauthorized access. Use the correct portal." This prevents privilege confusion.
- **Account status check**: If the user's `status` field is `pending` (awaiting admin approval), they are shown a message and cannot proceed.
- A real-time **status dialog** updates while login is in progress ("Authenticating...", "Finalizing..."), preventing double-taps and giving clear feedback.

#### Admin Login
Each admin portal has its own dedicated login page (`AdminLoginPage`) with:
- **Visual identity**: Each portal (Office Admin, Event Admin, HR Admin, Security Admin, Institution Admin) has its own distinct accent color, badge label, and portal title displayed on the login screen so the user always knows which portal they are accessing.
- **Math CAPTCHA**: Before every admin login attempt, the user must solve a randomly generated arithmetic problem (e.g., `7 + 4 = ?`). This is generated fresh on page load and refreshable. This prevents automated login scripts.
- **Database-level role enforcement**: Even after CAPTCHA, the system queries the database and checks both the `role` field and, for the three-level hierarchy, the `level` integer field. A Level 2 admin cannot log in through the Level 1 portal even with valid credentials.

#### Forgot Password (3-Step Self-Service Recovery)
Account recovery is a self-contained, three-step wizard available on the login screen:
1. **Step 1 — Identity**: User enters their Unique ID. The system retrieves their security question from the database.
2. **Step 2 — Verification**: The system presents the user's security question (chosen during registration). The user must answer it correctly (case-insensitive comparison).
3. **Step 3 — Reset**: The user sets a new password and confirms it. The new password is hashed with SHA-256 and saved. If no security question was set, the user is directed to contact their admin.

#### Profile Settings
Logged-in employees can access their Profile Settings page to:
- View their display name and Unique ID (read-only).
- **Change their password**: Input a new password to update it. The system re-hashes it with SHA-256 before storing.
- **Update their account recovery security question and answer**: Choose from five predefined questions and update their answer, used for future self-service password resets.
- Profile photo is displayed from Appwrite Storage if set during registration.

#### Automatic Inactive Account Cleanup
A background maintenance routine (`cleanupInactiveAccounts`) is built into the service layer. When triggered, it:
1. Queries for all users whose `lastLogin` is older than the configured threshold (default: 60 days).
2. Deletes the user's profile picture from Appwrite Storage.
3. Deletes the user's document from the database.
This runs silently during the admin login flow without blocking the UI.

---

### 2. Student / Employee Portal

The `HomePage` is the main hub for employees/students. It uses **Appwrite Realtime** to subscribe to changes in the `classes` collection, meaning the home screen updates instantly without any manual refresh when a class is created, modified, or when an attendance request is accepted.

The home screen categorises classes into the following visual sections:

#### My Classes
Classes in which the user is an enrolled member (their username exists in the class's `studentIds` array). Each class card is tappable and navigates to the Class Detail Page.

#### Invited Classes
If an admin has directly added the user's username to a class's `invitedStudents` list (inside the `boundary` JSON metadata), the class appears in this section with a special "Invited" indicator. These classes jump the queue — the user is auto-enrolled without needing to request access.

#### Pending Requests
Classes to which the user has submitted a join request, but the admin has not yet approved or rejected them. The class card displays a "Pending" status badge, giving the user real-time visibility into the approval queue.

#### Rejected Requests
Classes where the user's join request was explicitly rejected by the admin. This is displayed separately so the user understands they need to contact the admin if they believe the rejection was an error.

#### Explore Your Department
Classes created by admins within the same department as the user (determined by matching the `department` field on the user record against admins who created those classes). Users can browse and request to join these classes.

#### New Class Acceptance Notification
When a user's join request is approved and the class is added to their enrolled list between two data fetches, the home page **automatically detects the new class** and displays an animated in-app notification dialog: "Request Accepted! You've been added to [Class Name]." This dialog auto-dismisses after 4 seconds.

---

### 3. Attendance System

The attendance system is the core function of upasthiti. It is multi-layered, combining time-based session windows, GPS verification, and AI face verification.

#### Class Detail Page
When a student taps a class, they land on the `ClassDetailPage`, which is the primary interface for marking attendance. This page shows:
- Class name and metadata.
- Current date and time.
- Attendance history logs for the class.
- A "Mark Attendance" button (active only when an attendance period is open).

#### Attendance Periods (Time Windows)
Admins create time-bounded **attendance periods** for each class (stored in a `periods` sub-collection under each class). Each period has a `startTime` and `endTime`. A student can only mark attendance when:
- The **current system time falls within 10 minutes before the start time and 10 minutes after the end time** of an active period. This ±10-minute grace window accommodates minor delays without compromising session integrity.

#### Attendance Marking Workflow (Full Flow)
When a student taps "Mark Attendance":

1. **Geofence Check** (if a boundary is set): The system reads the device's current GPS coordinates and calculates the Haversine distance to the class boundary's centre point. If the user is outside the configured radius, attendance marking is blocked. (See Geofencing section below.)

2. **Camera Launch**: The device camera opens to capture a **live photo**.

3. **Face Verification API Call**: The captured photo is sent via HTTP multipart `POST` to the Hugging Face ML backend (`/login-face`) along with the user's username. The API compares the submitted photo against the stored face embedding for that user. (See Face Recognition section below.)

4. **Photo Upload**: If face verification succeeds, the captured photo is uploaded to the `attendance_photos` bucket in Appwrite Storage, creating a permanent, timestamped photographic audit trail.

5. **Log Creation**: An attendance log document is created in the `attendance_logs` collection with:
   - `username` — the student's unique ID
   - `classId` — the class being attended
   - `periodId` — the active period identifier
   - `timestamp` — the exact ISO-8601 timestamp of the mark
   - `photoUrl` — the direct view URL of the uploaded photo
   - `adminVerifiedStatus` — defaults to `Pending` until reviewed by an admin

6. **Success Confirmation**: The student sees a success message confirming attendance has been recorded.

#### Admin-Side Attendance Verification
Admins can review attendance logs and manually override the `adminVerifiedStatus` of any entry. Possible statuses are:
- `Pending` — submitted by student, awaiting admin review
- `Present` / `Verified` — confirmed as legitimate by admin
- `Absent` — flagged or manually marked absent

---

### 4. Geofencing

Geofencing is a configurable per-class feature. Admins can draw a **circular geographic boundary** on an interactive map when creating or editing a class.

#### How Geofencing Works
- The boundary is stored as a JSON object in the class's `boundary` field with three values: `lat` (latitude of centre), `lng` (longitude of centre), and `radiusMeters`.
- When a student attempts to mark attendance, the app uses the `geolocator` package to obtain a **high-accuracy GPS fix** from the device.
- The **Haversine formula** (computed by `Geolocator.distanceBetween()`) calculates the straight-line distance in metres between the student's position and the boundary centre.
- If the distance exceeds the radius, a dialog is shown explaining the student is outside the boundary, and attendance marking is blocked.
- If the class has no boundary configured, geofence checking is skipped entirely.

#### Boundary Map in Admin Portal
In the admin portal, when creating or editing a class, admins see a full `flutter_map` (OpenStreetMap) widget. They can:
- Tap on the map to set the centre point.
- Use a slider to adjust the radius (in metres).
- See a visual circle drawn on the map representing the exact geofence area.
- Use a "Use My Location" button to automatically set the centre to their current GPS position.

---

### 5. AI-Powered Face Recognition

upasthiti integrates a remote face recognition service hosted on Hugging Face Spaces for identity verification.

#### Face Registration (During Onboarding)
When a new user registers, they must take a **frontal selfie** using the device camera. This image is sent via HTTP multipart `POST` to the `/register-face` endpoint of the ML backend, along with their unique username. The backend processes the image and stores a **face embedding** (a mathematical vector representation of the face) indexed by username.

#### Face Verification (During Attendance)
When marking attendance, the user takes a live photo. This is sent to the `/login-face` endpoint. The backend computes the embedding of the submitted face and compares it against the registered embedding for the given username. The API returns a JSON response with:
- `{ "verified": true }` — identity confirmed, attendance proceeds.
- `{ "error": "..." }` — identity mismatch or processing error, attendance is blocked.

#### Cold-Start Retry Logic
The Hugging Face Spaces platform may take 30–60 seconds to "warm up" if the service has been idle. upasthiti handles this gracefully:
- Both registration and verification calls include a **3-attempt retry loop** with an exponential backoff delay (3 seconds, 6 seconds, 9 seconds).
- On retry attempts 2 and 3, a snackbar is shown to the user: "AI model warming up… Retry 2/3".
- Each request has a **60-second timeout** to accommodate the warm-up period.
- If all 3 attempts fail, a clear error is returned to the user.

#### Windows Desktop Camera Workaround
The `image_picker` camera source does not function on Windows desktop. The app detects the platform and on Windows:
1. Opens a locally bundled `camera.html` helper file in the system's default browser (using `url_launcher`).
2. Instructs the user to capture a photo and save it.
3. Immediately opens a file gallery picker so the user can select the saved photo.
This provides functional face capture on Windows desktop deployments.

---

### 6. Community (Messaging)

Each class has a built-in communication system, the `CommunityPage`, accessible from the Class Detail Page. It uses **Appwrite Realtime** to push new messages to all participants instantly.

#### Channel Tab (Public Class Broadcast)
The "Channel" tab is a class-wide broadcast channel. Messages sent here are visible to all enrolled students and the admin. Senders' names are displayed above each message bubble. Admins' messages are visually distinguished with a coloured indicator (`isAdmin: true` flag).

#### Direct Messages Tab
- **For students**: A private, one-on-one direct message thread between the student and the class admin. The student sees only their own conversation with the admin.
- **For admins**: A list of all enrolled students. Tapping any student opens their private DM thread. The admin can message any student individually from this view.

#### Message Features
- **Text messages**: Plain text, with a send button and keyboard "Done" action.
- **File attachments**: Users can select and upload any file type using the `file_picker` package. Files are uploaded to the `community_files` Appwrite Storage bucket. Uploaded files are displayed as download-able attachment cards in the chat showing the file name and type.
- **Timestamps**: Every message displays a relative or absolute timestamp.
- **Realtime delivery**: New messages appear instantly via Appwrite Realtime WebSocket subscription on `community_messages` collection events. Outgoing messages are also immediately injected into the local state for zero-latency perceived delivery.

---

### 7. Leave Management System

A complete leave request lifecycle is built into the application, spanning employee submission through admin approval.

#### Leave Request Submission (Employee Side)
Available from the Class Detail Page. Employees fill in:
- **Leave Category**: Medical, Casual, Paid Leave, or LTC - Tour Leave (selected via dropdown).
- **Duration**: A date range picker (calendar-style) for selecting start and end dates.
- **Reason**: A text field (up to 500 characters) for providing written justification.

The request is routed to the appropriate approver using `AdminHierarchyService.resolveApprovers()`. The resolver determines which admin is the correct approver based on the requester's level in the hierarchy:
- A Level 3 admin's leave request goes to a Level 2 admin.
- A Level 2 admin's leave request goes to a Level 1 admin.

#### Leave Management (Admin Side)
All admin portals that handle leave show a list of **incoming pending requests** addressed to them. Admins can:
- **Approve** — changes the request `status` to `approved`.
- **Reject** — changes the request `status` to `rejected` with an optional reason.

Leave request history is visible to both the requester (in their admin portal under "My Requests") and the approver.

#### HR Admin — Dedicated Leave Module
The HR Admin portal has a dedicated `_HRLeaveTab` for centralized management:
- Views **all pending leave requests** across their department.
- Approves or rejects requests with a reason.
- Exports leave data to CSV or Excel for HR reporting.

---

### 8. Distribution System

The Distribution System manages the physical or digital distribution of materials (uniforms, equipment, certificates, documents, etc.) at institutional events.

#### Event Lifecycle (Admin → Recipient → Acknowledgement)
1. **Create Event**: Admins or the Dean create a distribution event with a title, description, location, and scheduled date. New events start in `draft` status.
2. **Add Recipients**: The admin uploads a recipient list (Excel file) or adds students individually. Each recipient gets an entry in the `event_recipients` collection with `status: pending`.
3. **Activate Event**: The admin changes the event status from `draft` to `active`. This makes it visible to assigned QR scanner admins.
4. **Assign Scanner Admins**: The event creator assigns specific admin users as "scanner admins" for the event. Only assigned admins can scan QR codes for that event.
5. **QR Code Scanning (Distribution Day)**: The scanner admin opens the `AdminScanPage`, selects the active event, and uses the device camera to scan QR codes. The scanner reads the student's unique QR code and:
   - **Success**: Marks the recipient's status as `issued`, records the `issuedAt` timestamp and `issuedBy` admin ID.
   - **Already Issued**: Returns a warning — this student has already received their item.
   - **Not In List**: Returns a warning — this student is not a registered recipient for this event.
   - **Event Not Active**: Scanning is blocked if the event is not in `active` status.
   - All scan attempts are logged in the `distribution_scan_logs` collection with action type (`issued`, `duplicate_attempt`, `ineligible`, etc.).
6. **Student QR Code Page**: Each student has a "My QR Code" page showing their personalized QR code (containing their encoded username) alongside a list of any active distribution events they are registered for.
7. **Acknowledgement**: After receiving their item (when their status is `issued`), the student taps "Got it" on their QR page. This records an `acknowledgedAt` timestamp and changes their status to `acknowledged`, closing the distribution loop.

#### Dean-Level Distribution Management
The Super Admin (Dean) has a dedicated `DeanDistributionTab` with full visibility over all distribution events institution-wide: creating events, managing recipient lists, bulk-importing from Excel, assigning scanner admins, and closing events.

---

### 9. Institution Admin Portal (Level 1)

The Level 1 admin (`AdminHomePage` with `adminLevel: 1`) is the highest-level hierarchical admin, with the broadest scope.

**Classes Tab:**
- View all classes across the entire institution (not scoped to a department).
- Create new classes with name, subject, description, geofence boundary, and schedule.
- Edit existing classes.
- Invite specific students to a class by username.
- Assign Level 2 (Head of Department) and Level 3 (Team Leader) supervisors to classes.
- Manage join requests: approve or reject pending student enrollment requests.
- Delete classes.

**Attendance Logs Tab (Global Feed):**
- See a **paginated, real-time feed** of every attendance log across all classes they manage.
- Logs load in batches of 50 with **infinite scroll pagination** — when the user scrolls near the bottom of the list, the next batch is fetched automatically using cursor-based pagination (`Query.cursorAfter(lastId)`).
- **Filter by date range**: Select a start and end date to narrow the log view.
- **Filter by class**: Filter logs to show only a specific class.
- **Multi-select and bulk actions**: Enter "selection mode" by long-pressing a log entry, then select multiple entries to perform bulk operations.
- **CSV Export**: Export the filtered logs to a CSV file.
- **Realtime updates**: The logs tab subscribes to the `attendance_logs` collection via Appwrite Realtime and refreshes automatically when new logs arrive.

**Settings Tab:**
- View pending student registration approvals.
- Access the Organizational Chart.
- Access the Student Directory.
- Submit or view leave requests.
- Distribution event management.

---

### 10. Head of Department Portal (Level 2)

The Level 2 admin operates at department scope. They see classes assigned to their supervision via the `AdminHierarchyService.fetchClassesForAdmin()` method, which checks both direct class creation and supervisor assignments in the `boundary` metadata. All features from Level 1 are available but scoped to their department.

---

### 11. Team Leader Portal (Level 3)

The Level 3 admin manages individual classes they created. They have the full Class Management interface (create attendance periods, manage students, view logs, access community), but their analytics and logs are scoped strictly to their own classes.

---

### 12. Office Admin Portal

The Office Admin (`OfficeAdminHomePage`) is a **cross-cutting operational role** with no place in the admin level hierarchy. It is accessed via its own dedicated portal. The portal has a six-tab bottom navigation:

**Tab 1 — Overview:**
- Live dashboard statistics: total students in department, number of students with biometrics enrolled, today's attendance entries.
- All statistics load from the database on mount.

**Tab 2 — Students:**
- A searchable, scrollable directory of all students in the Office Admin's department.
- Tap any student to open their full individual attendance record (see below).

**Tab 3 — Reports:**
- Generate department-wide attendance reports.
- Filter by date range.
- **Export to PDF**: Creates a formatted PDF document with student-by-student attendance summaries, downloadable directly from the device.
- **Export to CSV**: Generates a structured CSV of attendance records.
- **Export to Excel (XLSX)**: Creates a multi-sheet Excel workbook with detailed logs.

**Tab 4 — Biometrics:**
- View each student's biometric enrollment status (whether they have a registered face embedding).
- **Re-register a student's face**: The Office Admin can capture a new photo for any student and re-submit it to the ML backend to update the face embedding, useful when a student's appearance has changed significantly.

**Tab 5 — Verify:**
- A manual identity verification interface. The admin can look up any student and perform an ad-hoc face verification check independent of any attendance session.

**Tab 6 — Audit Trail:**
- View a log of all actions performed by or affecting the Office Admin's department, for accountability purposes.

#### Per-Student Attendance Page
When an Office Admin taps a student in the Students tab, they open the `OfficeAdminStudentAttendancePage`. This page provides:
- Student profile photo and name.
- **Summary statistics**: Total Present, Absent, and Pending count for the filtered period.
- **Filters**: Filter by a specific class (dropdown of all classes the student is in) and/or a date range.
- **Grouped log view**: Logs are grouped by date in descending chronological order.
- Each log entry shows: class name, period, timestamp, and `adminVerifiedStatus` with colour-coded badges.

---

### 13. HR Admin Portal

The HR Admin (`HrAdminHomePage`) handles human resource functions. It is a cross-cutting role with four tabs:

**Dashboard Tab:**
- Overview of HR metrics: total active employees, pending leave requests, recent activity.

**Approvals Tab (`_HRApprovalsTab`):**
- Pending student/employee registration requests for the HR admin's department.
- Approve or reject registrations with one tap.

**Leave Tab (`_HRLeaveTab`):**
- Centralized inbox of all leave requests addressed to the HR Admin.
- Approve or reject requests, with the action recorded as `actionBy` and `actionById` in the leave record.
- View the full leave history of any employee.

**Reports Tab (`_HRReportsTab`):**
- Generate comprehensive leave and attendance reports.
- Filter by department, leave type, date range, or status.
- Export to CSV or Excel for payroll or compliance records.

---

### 14. Event Admin Portal

The Event Admin (`EventAdminHomePage`) is a cross-cutting role dedicated exclusively to managing institutional events. It has three tabs:

**Events Tab (`_EventsTab`):**
- Create new events with title, description, date, location, and capacity.
- View all events (draft, active, closed) they have access to.
- Change event status (activate or close events).
- Manage recipient lists: add individuals or bulk-import via Excel.

**Kiosk Tab (`_KioskTab`):**
- The QR code scanner interface for distribution events.
- Select an active event from a dropdown.
- Scan student QR codes using the device camera (`mobile_scanner`).
- Instant scan result feedback: success (green), already issued (yellow warning), not in list (red error), etc.

**Tracking Tab (`_TrackingTab`):**
- View per-event distribution progress: how many recipients have been issued, how many are still pending, and how many have acknowledged receipt.
- View the full scan log for any event.

---

### 15. Security Admin Portal

The Security Admin (`SecurityAdminHomePage`) is a dedicated monitoring and access-control role with three tabs:

**Audit Logs Tab (`_AuditLogsTab`):**
- A paginated, searchable log of all attendance events and system actions institution-wide.
- Filterable by user, class, or date.
- Provides a full accountability trail for security investigations.

**Anomalies Tab (`_AnomaliesTab`):**
- Detects and surfaces **suspicious attendance patterns**, particularly geofence-related anomalies (e.g., attendance marked from a location far outside the geofenced boundary, or multiple attempts in a short window).
- Flags these records for security review.

**Access Control Tab (`_AccessControlTab`):**
- View and manage account statuses for all users.
- Ability to suspend or reactivate accounts.
- View login history and last-active timestamps.
- Monitor for accounts that have not been accessed in an extended period.

---

### 16. Super Admin Portal (Dean)

The Dean (`DeanHomePage`) is the highest authority in the system, with **institution-wide executive control**. The portal is styled distinctly with a dark navy-and-gold color scheme (`kDeanGold = #D4AF37`) to visually differentiate it from all other portals. It has a custom animated tab navigation with a slide-left/slide-right transition between tabs.

**Tab 1 — Admin Personnel:**
- View every admin across all levels and departments institution-wide.
- Create new admin accounts (levels 1, 2, 3, Office, Event, HR, Security).
- Edit admin details, reassign departments, change levels.
- View each admin's profile picture, department, and leave history.
- **Leave Management**: The Dean has a dedicated leave inbox for Level 1 admins who report directly to them.
- Approve or reject Level 1 admin leave requests.

**Tab 2 — Distribution:**
- Full access to the distribution event system (`DeanDistributionTab`).
- Create events, manage recipient lists, assign scanner admins, activate, and close events.
- Export distribution logs to Excel.
- View real-time scan statistics for any active event.

**Tab 3 — Admin Reports:**
- Institution-wide attendance analytics and reports.
- Cross-department comparison views.
- Export to Excel.
- Filter by date range, department, admin level, or class.

**Tab 4 — System Settings ("More"):**
- **System Configuration**: Modify global platform settings.
- **Geofence Defaults**: Set institution-wide default geofence parameters.
- **About**: System version and platform information.
- **Logout**: Secure logout with confirmation dialog.

---

### 17. Organizational Chart

The `AdminOrgChartPage` renders a **visual tree-based organizational hierarchy** of all administrators in the institution. It is accessible to all admin levels from their settings.

- The chart is built by fetching all admin users and all classes, then inferring parent-child relationships from the `headAdminId` and `supervisorId` fields embedded in each class's `boundary` JSON.
- Each node displays the admin's profile photo (or an initial avatar), name, department, and role label (Institution Admin, Head of Department, Team Leader).
- **Cross-cutting roles** (Office Admin, Event Admin, HR Admin, Security Admin) are rendered separately at the top in a "Cross-Cutting Roles" section, since they operate institution-wide outside the standard hierarchy.
- The current logged-in admin is **highlighted** with a coloured border for quick self-identification.

---

### 18. Student Registration Approval Workflow

Registrations do not go live immediately. The full workflow is:

1. **Student self-registers** (see Registration below): Submits name, unique ID, department, photo, location, security Q&A, and password.
2. **Face is registered** with the ML backend.
3. **Profile photo** is uploaded to Appwrite Storage.
4. **User document** is created in the `users` collection with `status: "pending"`.
5. **Admin sees the request**: The `AdminApprovalRequestsPage` subscribes to the `users` collection via Realtime. Pending registrations appear instantly for the admin of the matching department.
6. **Admin approves or rejects**: Approval sets `status: "active"`, allowing the student to log in. Rejection can be done with a reason.
7. **Student attempts login**: If still `pending`, they see "Your account validation is pending from the admin." They are not blocked from trying again — they will succeed as soon as the admin approves.

#### Registration Form Fields
- **Full Name**
- **Unique ID** (the username used for login)
- **Department / School** (selected from a bottom sheet picker with 8 pre-configured school options)
- **Security Question** (selected from 5 predefined questions, stored for password recovery)
- **Security Answer**
- **Profile Photo** (camera capture; uploaded to Appwrite Storage; also registered with face recognition ML backend)
- **Location** (GPS coordinates captured once; stored as `latitude` and `longitude` on the user document — used as the user's registered home/work location)
- **Password + Confirm Password** (hashed with SHA-256 before storage)

---

## Security & Data Privacy

### Password Security
- All passwords are stored as **SHA-256 hashes** (64-character hex strings).
- A **dual-mode verifier** (`AppwriteService.verifyPassword`) supports both legacy plaintext and hashed passwords during a migration window.
- On every login with a plaintext password, the system automatically upgrades it to a hash without requiring any action from the user.
- Minimum password length is enforced at 6 characters.

### Role Enforcement
- Role verification happens on **both the client** (checked before navigation) and is **re-verified in every database query** (queries include role filters that would fail for wrong-role accounts even if the UI was bypassed).
- The Super Admin portal is hidden behind a **secret gesture** (5 rapid taps on the logo) — there is no visible button or menu entry pointing to it.

### Admin CAPTCHA
Every admin login form requires solving a **randomly generated arithmetic CAPTCHA** before credentials are submitted. This prevents automated login attempts against admin accounts.

### Audit Trail
Every attendance marking event creates a permanent record in `attendance_logs` including the student's ID, the class, the timestamp, the geofence result, and a URL to the captured photo. This data is immutable from the student's side and is available for review and export by Office Admins and the Security Admin.

### Photo Evidence
Attendance photos are stored in a dedicated Appwrite Storage bucket (`attendance_photos`) and referenced by URL in the attendance log. The URL is direct-access via the Appwrite Storage API, tied to the specific project, preventing unauthorized access.

### Inactive Account Purging
The platform has a built-in routine to delete accounts inactive for more than 60 days, including their stored profile photo from cloud storage, to minimize data retention risk.

---

## Realtime Capabilities

upasthiti uses **Appwrite Realtime (WebSocket)** extensively to ensure every user sees live data without manual refresh:

| Screen | Subscribed Collection | Effect |
|---|---|---|
| Student Home | `classes` | Instantly shows new classes, accepted requests |
| Admin Classes Tab | `classes` | New/modified classes appear live |
| Admin Logs Tab | `attendance_logs` | New attendance entries appear immediately |
| Community Channel | `community_messages` | New messages appear without refresh |
| Admin Approval Requests | `users` | New pending registrations appear immediately |
| Distribution Tab | `distribution_events` | Event status changes reflect immediately |

Each subscription is established in `initState()` and closed in `dispose()` to prevent memory leaks.

---

## Export & Reporting

upasthiti provides multiple export formats across different admin portals:

| Format | Available In | Content |
|---|---|---|
| **CSV** | Admin (Level 1), Office Admin, HR Admin | Attendance logs, leave records |
| **Excel (XLSX)** | Dean, Office Admin, HR Admin, Event Admin | Multi-sheet workbooks with detailed records |
| **PDF** | Office Admin | Formatted attendance summary reports |

Exports are generated entirely on-device using the `csv`, `excel`, and `pdf` packages. Files are saved to the device's documents directory via `path_provider` and on Android require the `WRITE_EXTERNAL_STORAGE` permission (handled via `permission_handler`).

---

## Dependencies & Libraries

| Package | Version | Purpose |
|---|---|---|
| `appwrite` | ^23.1.0 | Backend-as-a-Service SDK |
| `image_picker` | ^1.0.7 | Camera and gallery photo capture |
| `file_picker` | ^10.3.8 | File attachment selection for community chat |
| `http` | ^1.6.0 | HTTP client for ML backend API calls |
| `geolocator` | ^10.1.0 | GPS location and permission management |
| `camera` | ^0.11.3 | Low-level camera access |
| `path_provider` | ^2.1.5 | Device storage paths for file export |
| `webview_flutter` | ^4.13.1 | In-app web content rendering |
| `url_launcher` | ^6.3.2 | Open external URLs and files |
| `desktop_multi_window` | ^0.3.0 | Multi-window support on desktop |
| `webview_windows` | ^0.4.0 | WebView support for Windows |
| `crypto` | ^3.0.6 | SHA-256 password hashing |
| `flutter_map` | ^8.2.2 | Interactive map with OpenStreetMap tiles |
| `latlong2` | ^0.9.1 | Geographic coordinate types for flutter_map |
| `google_mlkit_face_detection` | ^0.11.0 | On-device face detection (client-side assist) |
| `csv` | ^6.0.0 | CSV file generation |
| `permission_handler` | ^12.0.1 | Runtime permission requests (storage, camera, GPS) |
| `intl` | ^0.19.0 | Date/time formatting and internationalisation |
| `google_fonts` | ^6.2.1 | Poppins font and Google Fonts integration |
| `qr_flutter` | ^4.1.0 | QR code generation (student QR page) |
| `mobile_scanner` | ^5.2.3 | QR code scanning (distribution kiosk) |
| `excel` | ^4.0.6 | Excel workbook generation and parsing |
| `pdf` | ^3.12.0 | PDF document generation |
| `printing` | ^5.14.3 | PDF sharing and printing |

---

<div align="center">
  <p>Built with ❤️ by <strong>Navonmesh Samadhan LLP</strong></p>
  <p><em>Secure, Smart, Verified.</em></p>
</div>
