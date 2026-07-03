<p align="center">
  <img src="assets/upasthiti.png" alt="Upasthiti Logo" width="180"/>
</p>

<h1 align="center">उपस्थिति — Upasthiti</h1>

<p align="center">
  <strong>AI-Powered Attendance & Campus Management Platform with Face Verification, Geofencing & QR Distribution</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Appwrite-Cloud-F02E65?style=for-the-badge&logo=appwrite&logoColor=white" alt="Appwrite"/>
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Windows%20|%20Web-green?style=for-the-badge" alt="Platform"/>
</p>

<p align="center">
  <em>Upasthiti (उपस्थिति — Sanskrit for "presence") is a comprehensive, multi-role campus management platform built with Flutter and Appwrite. It combines <strong>AI-powered face recognition</strong>, <strong>GPS geofencing</strong>, <strong>QR-based distribution tracking</strong>, and <strong>real-time data sync</strong> to deliver a tamper-proof, modern experience for educational institutions — from attendance and HR to event logistics and security auditing.</em>
</p>

---

## 📖 Table of Contents

- [✨ Features](#-features)
- [🛠 Tech Stack](#-tech-stack)
- [🏗 Architecture Overview](#-architecture-overview)
- [🚀 Installation & Setup](#-installation--setup)
- [📱 Usage](#-usage)
- [📸 Screenshots](#-screenshots)
- [📂 Folder Structure](#-folder-structure)
- [🔌 API & Backend Details](#-api--backend-details)
- [🔒 Security Notes](#-security-notes)
- [🗺 Future Improvements](#-future-improvements)
- [🤝 Contributing](#-contributing)

---

## ✨ Features

### 🔐 Authentication & Access Control

| Feature | Description |
|---|---|
| **Multi-role login** | Separate portals for Students, Office Admins, HR Admins, Security Admins, Event Admins, and Dean (Super Admin) |
| **CAPTCHA-protected admin login** | Prevents brute-force attacks on admin portals |
| **Hidden Dean portal** | Accessible via a secret 5-tap easter egg on the login screen |
| **Role-Based Access Control (RBAC)** | Prevents cross-role portal access |
| **Account status management** | Admins can be suspended/reactivated by the Dean |
| **Admin level hierarchy (L1–L3)** | Controls feature access, approval chains, and supervision |
| **Dual-mode password verification** | Supports legacy plaintext + auto-upgrade to SHA-256 hashed passwords |
| **Security question recovery** | Students can reset passwords via a self-serve security question flow |
| **Forgot Password** | 3-step recovery: Username → Security Question → Reset Password |
| **Profile picture storage** | Photos stored in Appwrite Storage and displayed in user profiles & admin approval pages |

### 📋 Attendance Management

| Feature | Description |
|---|---|
| **AI-powered face verification** | Students must pass face recognition before logging attendance |
| **GPS geofencing** | Attendance only accepted within the class boundary radius |
| **Period-based scheduling** | Admins define time windows; students report within active sessions |
| **Entry status tracking** | Records whether entry was Early, Within Window, or Late |
| **Photo upload & storage** | Captured selfies stored in Appwrite Storage |
| **Admin verification workflow** | Attendance marked as Present, Late, Absent, or Pending |
| **Attendance history** | Students view full history per class with status indicators |

### 🗺 Geofencing & Boundary Management

- **Interactive map boundary picker** — powered by OpenStreetMap via `flutter_map`
- **Configurable radius** (30m – 500m) — adjustable per class
- **Real-time location verification** — checks GPS coordinates against boundary on report
- **Visual boundary indicators** — "In Zone" / "Out of Zone" chips on attendance logs

### 🏢 Multi-Portal Admin System

> **6 distinct admin roles**, each with a purpose-built dashboard:

| Portal | Dashboard | Key Capabilities |
|---|---|---|
| **Office Admin** | `OfficeAdminHomePage` | Student approvals with profile images, biometric face enrollment, student directory, individual attendance tracking, CSV/Excel/PDF export |
| **HR Admin** | `HrAdminHomePage` | Employee approvals, leave management, reporting & analytics, CSV/Excel export |
| **Security Admin** | `SecurityAdminHomePage` | Audit logs, anomaly detection, access control management |
| **Event Admin** | `EventAdminHomePage` | QR-based distribution events, live scanning, recipient tracking |
| **Dean (Super Admin)** | `DeanHomePage` | Personnel management, supervision mode, org chart, system-wide distribution events |
| **L1/L2/L3 Admin Hierarchy** | `AdminLevelSelectPage` | Tiered approval workflows, head admin & supervisor assignments per class |

### 📦 QR Distribution System

- **Distribution events** — Create, manage, and close distribution events (e.g. materials handout, kit distribution)
- **QR code generation** — Each student receives a unique QR code for event check-in
- **Admin scanning** — Admins scan student QR codes to mark them as "received" in real-time
- **Excel upload** — Bulk import recipient lists from `.xlsx` files
- **Live progress tracking** — Real-time issued/total progress bars on each event
- **Admin assignment** — Event creators can assign other admins as scanners
- **Dean oversight** — Dean can create and manage distribution events across all departments

### 💬 Community & Messaging

- **Class channel** — public broadcast chat per class with real-time updates
- **Direct Messages** — private 1:1 messaging between admins and students
- **File attachments** — share PDFs, spreadsheets, images, and documents
- **Admin badges** — admin messages are visually distinguished in the chat
- **Real-time sync** — powered by Appwrite Realtime WebSocket subscriptions

### 📊 Analytics & Reporting

| Export Format | Available From |
|---|---|
| **CSV** | Admin dashboard, HR dashboard |
| **Excel (.xlsx)** | Office Admin, HR Admin |
| **PDF** | Office Admin reports |

- **Global attendance logs** — filterable by class and date range
- **Log selection & batch operations** — select, delete, or soft-delete logs
- **Delete by day** — granular cleanup of attendance records
- **Student count & boundary status** — visible per class on the admin dashboard
- **Individual student attendance tracking** — per-student attendance page with full history

### 📝 Leave Management

- **Leave request system** — Medical, Casual, Paid Leave, and LTC categories
- **Hierarchical approval chain** — Level N requests go to Level N+1 for approval
- **Approve / Deny workflow** — approvers can action requests with status tracking
- **Request history** — users can view their own leave requests and statuses

### 🎓 Dean (Super Admin) Dashboard

- **Personnel management** — onboard new admins with department, level, and credentials
- **Supervision mode** — enter any admin's dashboard to inspect their classes and logs
- **Account controls** — override passwords, suspend/reactivate, or delete admin accounts
- **Organizational chart** — visual tree view of the admin hierarchy (L1 → L2 → L3)
- **Data migration tool** — link unowned legacy classes and logs to the master account
- **Distribution event management** — create and manage events at the institutional level

### 👥 Student Approval & Directory

- **Multi-step registration** — Name, Unique ID, School, Photo, GPS Location, Security Question, Face Enrollment
- **Admin approval workflow** — Pending students appear with profile photos for approve/deny
- **Student directory** — Searchable list of all active students in a department
- **Invite to class** — Office Admins can invite students to their classes directly from the directory
- **Profile settings** — Students can update passwords and security questions

### 🛡 Security & Maintenance

- **Biometric face re-enrollment** — Office Admins can re-register a student's face directly from the dashboard
- **Anomaly detection** — Security Admins get flagged events for suspicious access patterns
- **Access control management** — Security Admins manage gate/room access
- **Audit logging** — Full audit trail for Security Admin review
- **Automated inactive account cleanup** — Accounts inactive for 60+ days are automatically purged (database record + profile photo) on admin login

### 🎨 UI/UX Design

- **Animated splash screen** — logo appear/disappear with scale and opacity transitions
- **Rising sheet pattern** — signature bottom-to-top slide + fade entrance across all screens
- **Poppins typography** — consistent Google Fonts throughout the app
- **Custom theme system** — centralized `AppTheme` with brand colors, input styles, and decorations
- **Hero animations** — smooth transitions between class list and detail views
- **Micro-animations** — tab switching, selection indicators, and status chip transitions
- **Bottom sheet selectors** — elegant modal pickers for schools, security questions, and more

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.10+ (Dart 3.x) |
| **Backend** | [Appwrite Cloud](https://appwrite.io) (Singapore region) |
| **Database** | Appwrite Databases (NoSQL documents) |
| **File Storage** | Appwrite Storage (attendance photos, profile pictures, community files) |
| **Real-time** | Appwrite Realtime (WebSocket subscriptions) |
| **Face Recognition** | Custom Python backend hosted on [Hugging Face Spaces](https://huggingface.co/spaces) |
| **Maps** | OpenStreetMap tiles via [`flutter_map`](https://pub.dev/packages/flutter_map) + [`latlong2`](https://pub.dev/packages/latlong2) |
| **Geolocation** | [`geolocator`](https://pub.dev/packages/geolocator) |
| **Typography** | [`google_fonts`](https://pub.dev/packages/google_fonts) (Poppins) |
| **Camera** | [`image_picker`](https://pub.dev/packages/image_picker) / [`camera`](https://pub.dev/packages/camera) |
| **CSV Export** | [`csv`](https://pub.dev/packages/csv) |
| **Excel Export** | [`excel`](https://pub.dev/packages/excel) |
| **PDF Generation** | [`pdf`](https://pub.dev/packages/pdf) |
| **Date/Time** | [`intl`](https://pub.dev/packages/intl) |
| **File Sharing** | [`file_picker`](https://pub.dev/packages/file_picker) |
| **URL Handling** | [`url_launcher`](https://pub.dev/packages/url_launcher) |
| **Permissions** | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| **Local Storage** | [`path_provider`](https://pub.dev/packages/path_provider) |
| **Cryptography** | [`crypto`](https://pub.dev/packages/crypto) (SHA-256 password hashing) |

---

## 🏗 Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Student   │ │ Office   │ │   HR     │ │ Security │            │
│  │ Portal    │ │ Admin    │ │  Admin   │ │  Admin   │            │
│  └────┬──────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘            │
│  ┌────┴──────┐ ┌────┴─────┐ ┌────┴─────┐                        │
│  │  Event    │ │  Dean    │ │ Shared   │                        │
│  │  Admin    │ │ (Super)  │ │ Services │                        │
│  └────┬──────┘ └────┬─────┘ └────┬─────┘                        │
│       └─────────────┴────────────┘                               │
│                      │                                           │
│    AppwriteService · DistributionService · LeaveService          │
│    AdminHierarchyService                                         │
└──────────────────────┬───────────────────────────────────────────┘
                       │ HTTPS / WSS
          ┌────────────┴────────────┐
          │    Appwrite Cloud       │
          │  ┌──────────────────┐   │
          │  │  users           │   │
          │  │  classes         │   │
          │  │  attendance_logs │   │
          │  │  periods         │   │
          │  │  community_msgs  │   │
          │  │  leave_requests  │   │
          │  │  distribution_   │   │
          │  │    events        │   │
          │  └──────────────────┘   │
          │  ┌──────────────────┐   │
          │  │  Storage Buckets │   │
          │  │  • attendance_   │   │
          │  │    photos        │   │
          │  │  • profile_      │   │
          │  │    pictures      │   │
          │  │  • community_    │   │
          │  │    files         │   │
          │  └──────────────────┘   │
          └────────────┬────────────┘
                       │
          ┌────────────┴────────────┐
          │  Face Recognition API   │
          │  (Hugging Face Spaces)  │
          │  • POST /register-face  │
          │  • POST /login-face     │
          └─────────────────────────┘
```

### Data Flow

1. **Registration** → Student captures photo + location + security question → Face registered on ML backend → Profile saved in Appwrite → Awaits admin approval
2. **Approval** → Office/HR Admin reviews pending students with profile images → Approve/Deny → Student status updated to `active`
3. **Attendance** → Student opens active class → GPS check against geofence → Camera capture → Face verification via API → Attendance log created in Appwrite
4. **Admin Review** → Realtime subscription updates admin dashboard → Admin verifies/marks each log → Status reflected to student in real-time
5. **Distribution** → Event Admin creates event → Uploads recipient list → Admins scan QR codes → Progress tracked in real-time
6. **Community** → Messages stored in `community_messages` collection → Realtime delivers to all subscribers instantly
7. **Cleanup** → On admin login, accounts inactive for 60+ days are automatically purged with their profile photos

---

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK** `>=3.10.4` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** `>=3.x` (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for cloning the repository

### 1. Clone the Repository

```bash
git clone https://github.com/yawansharma/Navikarana.git
cd Navikarana
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Appwrite (Backend)

The app connects to **Appwrite Cloud**. To use your own instance:

1. Open `lib/services/appwrite_service.dart`
2. Replace the endpoint and project ID:

```dart
class AppwriteService {
  static const String endpoint = 'https://your-appwrite-instance/v1';
  static const String projectId = 'your-project-id';
  static const String databaseId = 'your-database-id';
  static const String profileBucketId = 'your-bucket-id';
  // ...
}
```

3. Create the required database collections (see [API & Backend Details](#-api--backend-details))
4. Add the following **String attributes** to the `users` collection:
   - `securityQuestion` (Size: 100)
   - `securityAnswer` (Size: 100)
5. Add a **Datetime attribute** called `lastLogin` to the `users` collection and create an index on it

### 4. Configure Face Recognition Backend

The face verification API is hosted on Hugging Face Spaces. To use your own:

1. Open `lib/services/appwrite_service.dart`
2. Update the backend URL constant: `mlBackendBase`

### 5. Run the App

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows Desktop
flutter run -d windows

# Web
flutter run -d chrome
```

### 6. Build for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

---

## 📱 Usage

### 🎓 Student Workflow

1. **Register** → Create account with photo, location, school selection, security question, and face registration
2. **Await Approval** → Your account stays `pending` until an Office/HR Admin approves it
3. **Login** → Enter unique code and password
4. **Join Class** → Use the class code provided by your admin
5. **View Schedule** → See today's active/upcoming sessions on the dashboard
6. **Report Attendance** → Open active class → GPS verification → Face scan → Done!
7. **Chat** → Access the Community page to message classmates or your admin
8. **Track History** → View attendance history with Present/Late/Absent/Pending status
9. **QR Code** → View your personal QR code for distribution events
10. **Forgot Password?** → Recover access via your security question

### 🏢 Office Admin Workflow

1. **Login** → Use admin credentials with CAPTCHA verification
2. **Approve Students** → Review pending registrations with profile photos → Approve/Deny
3. **Student Directory** → Browse all students in your department, invite to classes
4. **Biometrics** → Re-enroll student faces directly from the dashboard
5. **Reports** → Export attendance data as CSV, Excel, or PDF
6. **Individual Tracking** → View per-student attendance across all classes

### 👤 HR Admin Workflow

1. **Dashboard** → View department-wide statistics and pending approvals
2. **Approvals** → Approve/deny new account requests
3. **Leave Management** → Review and action leave requests
4. **Reports** → Generate CSV/Excel reports

### 🛡 Security Admin Workflow

1. **Audit Logs** → Review all system access logs
2. **Anomalies** → Investigate flagged suspicious activities
3. **Access Control** → Manage gate/room permissions

### 📦 Event Admin Workflow

1. **Create Events** → Set up distribution events with title, description, date, location
2. **Upload Recipients** → Import from Excel or add manually
3. **Assign Scanners** → Delegate scanning to other admins
4. **Scan QR Codes** → Use the built-in scanner to mark items as distributed
5. **Track Progress** → Real-time progress bars show issued vs total

### 👔 Dean (Super Admin) Workflow

1. **Access** → Hidden portal via 5-tap easter egg on login screen
2. **Manage Admins** → Onboard, suspend, override passwords, or delete admins
3. **Org Chart** → Visualize the full admin hierarchy tree (L1 → L2 → L3)
4. **Supervise** → Enter any admin's dashboard in supervision mode
5. **Distribution** → Create and manage institution-wide distribution events
6. **System Maintenance** → Run data migration for legacy records

---

## 📸 Screenshots

> Screenshots of the app in action. Replace placeholders with actual images.

| Login | Student Dashboard | Class Detail |
|:---:|:---:|:---:|
| ![Login](screenshots/login.png) | ![Dashboard](screenshots/dashboard.png) | ![Class](screenshots/class_detail.png) |

| Admin Panel | Attendance Logs | Community Chat |
|:---:|:---:|:---:|
| ![Admin](screenshots/admin.png) | ![Logs](screenshots/logs.png) | ![Chat](screenshots/community.png) |

| Geofence Picker | Dean Portal | Leave System |
|:---:|:---:|:---:|
| ![Geofence](screenshots/geofence.png) | ![Dean](screenshots/dean.png) | ![Leave](screenshots/leave.png) |

---

## 📂 Folder Structure

```
lib/
├── main.dart                          # App entry, splash screen, student login, forgot password link
├── app_theme.dart                     # Centralized theme, colors, text styles, RisingSheet widget
│
├── register_page.dart                 # Student registration (photo + location + security Q + face)
├── forgot_password_page.dart          # 3-step password recovery via security questions
├── admin_login.dart                   # Admin login with CAPTCHA verification
├── dean_login.dart                    # Dean/Super Admin login portal
│
├── home_page.dart                     # Student dashboard — joined classes, today's sessions
├── class_detail_page.dart             # Class view — attendance, history, geofence check
├── profile_page.dart                  # Student profile — password & security question management
│
├── office_admin_home_page.dart        # Office Admin — approvals, students, reports, biometrics
├── office_admin_student_attendance_page.dart  # Individual student attendance tracking
├── hr_admin_home_page.dart            # HR Admin — dashboard, approvals, leave, reports
├── security_admin_home_page.dart      # Security Admin — audit logs, anomalies, access control
├── event_admin_home_page.dart         # Event Admin — distribution event management
├── dean_home_page.dart                # Dean — personnel, supervision, org chart, distribution
│
├── admin_approval_requests_page.dart  # Pending student approvals with profile images
├── admin_hierarchy_views.dart         # L1/L2/L3 hierarchy UI components
├── admin_level_select_page.dart       # Admin level selector for tiered features
├── admin_org_chart_page.dart          # Visual organizational chart (tree view)
├── admin_student_directory_page.dart  # Searchable student directory with invite-to-class
│
├── community_page.dart                # Class channel + DM messaging with file attachments
├── camera_page.dart                   # Camera integration for Windows desktop
├── eye_test_dialog.dart               # WebView-based eye test dialog (Windows)
│
├── leave_management_page.dart         # Leave request list + approval workflow
├── leave_request_page.dart            # Submit new leave request form
│
├── distribution/
│   ├── admin_distribution_tab.dart    # Event creation, detail view, scanning, Excel import
│   ├── admin_scan_page.dart           # QR code scanner for distribution events
│   ├── dean_distribution_tab.dart     # Dean-level distribution management
│   └── user_qr_page.dart             # Student QR code display page
│
├── components/
│   └── user_avatar.dart               # Reusable avatar widget (profile picture or initials)
│
├── services/
│   ├── appwrite_service.dart          # Appwrite client config + password hashing + inactive cleanup
│   ├── admin_hierarchy_service.dart   # Admin hierarchy CRUD (L1/L2/L3 assignments)
│   ├── distribution_service.dart      # Distribution event CRUD operations
│   └── leave_service.dart             # Leave request CRUD operations
│
├── backend/                           # (Reserved for future backend logic)
└── registered_faces/                  # (Local face registration data)

assets/
├── appLogo.png                        # App launcher icon
└── upasthiti.png                      # Brand logo used in splash screen and footers
```

---

## 🔌 API & Backend Details

### Appwrite Collections

| Collection | Description | Key Fields |
|---|---|---|
| `users` | All user accounts | `username`, `name`, `password`, `role`, `department`, `level`, `status`, `lastLogin`, `profilePictureId`, `securityQuestion`, `securityAnswer` |
| `classes` | Class/course records | `className`, `classCode`, `createdBy`, `adminName`, `studentIds[]`, `boundary` (JSON) |
| `attendance_logs` | Individual attendance entries | `userId`, `classId`, `adminId`, `periodId`, `timestamp`, `photoUrl`, `isWithinGeofence`, `isVerified`, `adminVerifiedStatus`, `entryStatus` |
| `periods` | Scheduled attendance windows | `classId`, `date`, `startTime`, `endTime` |
| `community_messages` | Chat messages (channel & DM) | `classId`, `channel`, `senderId`, `text`, `fileUrl`, `fileType`, `fileName`, `timestamp`, `isAdmin` |
| `leave_requests` | Leave request records | `userId`, `userName`, `leaveType`, `startDate`, `endDate`, `reason`, `status`, `approverLevel`, `actionBy` |
| `distribution_events` | Distribution events | `title`, `description`, `scheduledDate`, `location`, `createdBy`, `status`, `issuedCount`, `totalRecipients`, `createdAt` |
| `event_recipients` | Distribution recipients | `eventId`, `userId`, `userName`, `status`, `issuedAt`, `issuedBy`, `acknowledgedAt`, `packageNote` |
| `event_admin_assignments` | Admins assigned to events | `eventId`, `adminId`, `adminName`, `assignedBy`, `assignedAt`, `isActive` |
| `distribution_scan_logs` | QR scan audit trail | `eventId`, `scannedUserId`, `scannedBy`, `action`, `timestamp` |

### Storage Buckets

| Bucket | Purpose |
|---|---|
| `attendance_photos` | Selfie photos captured during attendance reporting |
| Profile pictures bucket (custom ID) | User profile pictures uploaded during registration |
| `community_files` | File attachments shared in community channels and DMs |

### Face Recognition API

| Endpoint | Method | Description |
|---|---|---|
| `/register-face` | `POST` | Register a new face with `username` + `image` (multipart) |
| `/login-face` | `POST` | Verify a face against registered data with `username` + `image` (multipart) |

> Hosted on Hugging Face Spaces — returns `{ "verified": true }` on success or `{ "error": "..." }` on failure.

---

## 🔒 Security Notes

> ⚠️ **Important:** This project is under active development. The following security considerations should be addressed before production deployment.

| Area | Current State | Production Recommendation |
|---|---|---|
| **Password Storage** | SHA-256 hashed with auto-upgrade from legacy plaintext | Migrate to Appwrite's native session-based authentication |
| **Dean Credentials** | Stored in database with role-based query | Add multi-factor authentication |
| **Database IDs** | Embedded in client code as static constants | Use environment variables or a configuration file |
| **Client-Side RBAC** | Role checks on the client side | Implement Appwrite ACLs and server-side permissions |
| **API Endpoints** | ML backend URL is a static constant | Use environment configuration per deployment |
| **Inactive Cleanup** | Auto-purge after 60 days of inactivity | Add admin notification before deletion |

---

## 🗺 Future Improvements

- [ ] **Migrate to Appwrite native auth** — Replace custom credential storage with session-based authentication
- [ ] **Server-side RBAC** — Enforce role-based access via Appwrite permissions and ACLs
- [ ] **Push notifications** — Notify students of upcoming classes and admins of new attendance logs
- [ ] **Offline support** — Cache attendance data locally and sync when connectivity is restored
- [ ] **Timetable integration** — Auto-generate periods from uploaded timetable data
- [ ] **Attendance analytics dashboard** — Charts and graphs for attendance trends, student performance
- [ ] **Multi-language support** — Hindi, English, and regional language localization
- [ ] **Dark mode** — Full dark theme support across all portals
- [ ] **Automated absence alerts** — Email/SMS notifications when students miss classes
- [ ] **Environment config** — Move all API URLs, project IDs, and secrets to env files
- [ ] **Biometric (fingerprint) login** — Native device biometric as alternative to face scan

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes with descriptive messages
   ```bash
   git commit -m "feat: add QR code attendance scanning"
   ```
4. **Push** to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Guidelines

- Follow the existing code style and architecture patterns
- Use the centralized `AppTheme` for all UI styling
- Add comments for complex logic
- Test on at least Android and Windows before submitting
- Use `AppwriteService` for all backend interactions
- Keep commit messages descriptive and follow [Conventional Commits](https://www.conventionalcommits.org/)

---

<p align="center">
  <sub>Built with ❤️ using Flutter & Appwrite</sub><br/>
  <sub><strong>उपस्थिति</strong> — Making Attendance Intelligent</sub>
</p>
