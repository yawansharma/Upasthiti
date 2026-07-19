# 15 — Folder Structure

## Repository Root

```
Navikarana/
├── lib/                        ← All Dart source code
├── assets/                     ← Image assets (logo files)
├── docs/                       ← This documentation folder
├── test/                       ← Flutter test placeholder (no active tests)
├── pubspec.yaml                ← Flutter project manifest + dependency declarations
├── pubspec.lock                ← Locked dependency versions
├── README.md                   ← Project readme (updated with full feature documentation)
├── generate_brochure.py        ← Python script (previous doc generation attempt)
├── generate_detailed_doc.py    ← Python script (generated Upasthiti_Comprehensive_Specification.docx)
├── android/                    ← Android platform project
├── ios/                        ← iOS platform project
├── windows/                    ← Windows platform project
├── linux/                      ← Linux platform project (not actively used)
├── macos/                      ← macOS platform project (not actively used)
└── web/                        ← Web platform project (not actively used)
```

---

## `lib/` Directory — Detailed

```
lib/
│
├── main.dart
│   Role: Application entry point. Contains:
│   - MyApp (MaterialApp root)
│   - SplashScreen (animated splash with logo)
│   - LoginPage (employee login with dual-mode verification)
│   - RisingSheet helper widget
│
├── app_theme.dart
│   Role: Global design system. Contains:
│   - AppTheme class with all color tokens, text styles, and decoration factories
│   - inputDecoration() factory for consistent text field styling
│   - bottomSheet BoxDecoration (white card with rounded top)
│   - sheetHandle widget (drag pill indicator)
│
├── register_page.dart
│   Role: New student/employee registration. Contains:
│   - Multi-field registration form
│   - GPS location capture
│   - Camera/file picker for selfie
│   - ML backend /register-face call with retry logic
│   - Appwrite profile photo upload
│   - User document creation with status: 'pending'
│
├── home_page.dart
│   Role: Student/employee dashboard. Contains:
│   - Realtime subscription on classes collection
│   - 5-section class list (My, Invited, Pending, Rejected, Explore)
│   - New class acceptance notification dialog
│   - Navigation to class detail, QR page, community
│
├── class_detail_page.dart
│   Role: Individual class view and attendance marking. Contains:
│   - Attendance period detection (±10 min window)
│   - Geofence check (Haversine)
│   - Camera capture
│   - ML verification call
│   - Attendance log creation
│   - Attendance history list
│
├── community_page.dart
│   Role: Class messaging. Contains:
│   - Channel tab (broadcast to all)
│   - DM tab (student: one thread; admin: list of students)
│   - File attachment upload/display
│   - Realtime message stream
│
├── profile_page.dart
│   Role: User account settings. Contains:
│   - Password change (hashed)
│   - Security question + answer update
│   - Profile photo display
│
├── forgot_password_page.dart
│   Role: Self-service password recovery. Contains:
│   - 3-step wizard (identity → verification → reset)
│   - Security question retrieval and answer comparison
│
├── leave_request_page.dart
│   Role: Leave submission form. Contains:
│   - Category dropdown (4 types)
│   - Date range picker
│   - Reason text area
│   - Hierarchy-based approver resolution and routing
│
├── admin_login.dart
│   Role: Admin authentication. Contains:
│   - Math CAPTCHA generation and validation
│   - Role + level enforcement post-credential verification
│   - Visual portal identity (accent colour, badge, title per role)
│
├── admin_level_select_page.dart
│   Role: Admin portal role/level selection. Contains:
│   - 7 level cards (L1, L2, L3, Office, Event, HR, Security)
│   - Each card shows role description and navigates to correct AdminLoginPage variant
│
├── admin_home_page.dart  (~4,000 lines)
│   Role: Unified portal for L1, L2, L3 admins. Contains:
│   - Tab 0: Classes (class list, create class, geofence picker, assign admins)
│   - Tab 1: Analytics (global attendance logs, date/class filter, multi-select, CSV export)
│   - Tab 2: Distribution (AdminDistributionTab)
│   - Tab 3: Settings (leave, student directory, approval requests, org chart)
│   - L1OrganizationPanel, ClassAssignmentChips, L2TeamTab (in admin_hierarchy_views.dart)
│
├── admin_hierarchy_views.dart
│   Role: Shared UI components for admin hierarchy features. Contains:
│   - L1OrganizationPanel (statistics summary for Level 1 admin)
│   - L2TeamTab (Level 2 department-view with admin list and their classes)
│   - ClassAssignmentChips (visual indicator of assigned L2/L3 on class cards)
│   - showClassStaffAssignmentSheet() (bottom sheet to assign L2/L3 to a class)
│
├── admin_org_chart_page.dart
│   Role: Visual organisational chart. Contains:
│   - Tree builder from admin documents + class boundary metadata
│   - Special roles section (Office/Event/HR/Security admins)
│   - Recursive node renderer with tree-line drawing
│
├── admin_approval_requests_page.dart
│   Role: Student registration approval queue. Contains:
│   - Realtime subscription on users collection
│   - Approve / reject actions
│   - Department-scoped filtering
│
├── office_admin_home_page.dart
│   Role: Office Admin portal. Contains:
│   - 6-tab navigation: Overview, Students, Reports, Biometrics, Verify, Audit Trail
│   - Student list with search
│   - PDF / CSV / Excel export
│   - Face re-registration workflow
│
├── office_admin_student_attendance_page.dart
│   Role: Per-student attendance detail viewer. Contains:
│   - Class filter and date range filter
│   - Computed stats (present/absent/pending counts)
│   - Grouped-by-date log display
│
├── hr_admin_home_page.dart
│   Role: HR Admin portal. Contains:
│   - 4 tabs: Dashboard, Approvals, Leave, Reports
│   - Leave approval/rejection with reason
│   - CSV/Excel leave export
│
├── security_admin_home_page.dart
│   Role: Security Admin portal. Contains:
│   - 3 tabs: Audit Logs, Anomalies, Access Control
│   - Audit Logs: searchable, date-filtered, full institution-wide view
│   - Anomalies: attendance logs with isWithinGeofence=false
│   - Access Control: user account management
│
├── event_admin_home_page.dart
│   Role: Event Admin portal. Contains:
│   - 3 tabs: Events, Kiosk (QR scanner), Tracking
│   - Event CRUD and status management
│   - QR scan kiosk with mobile_scanner
│
├── dean_home_page.dart  (~2,350 lines)
│   Role: Dean / Super Admin portal. Contains:
│   - 4 tabs: Personnel, Distribution, Reports, Settings
│   - Admin CRUD for all roles
│   - Leave approval for L1 admins
│   - Institution-wide analytics
│
├── dean_login.dart
│   Role: Dean-specific login flow. Contains:
│   - Accessed via 5-tap gesture on logo
│   - Credential check for role == 'dean'
│
├── admin_student_directory_page.dart
│   Role: Searchable student directory for L2/L3 admins.
│
├── services/
│   ├── appwrite_service.dart    ← SDK singleton, hashing, cleanup
│   ├── leave_service.dart       ← Leave request CRUD
│   ├── distribution_service.dart ← Distribution lifecycle + QR
│   └── admin_hierarchy_service.dart ← Hierarchy resolution
│
├── distribution/
│   ├── admin_distribution_tab.dart  ← Admin event management + realtime
│   ├── admin_scan_page.dart         ← QR scanner kiosk screen
│   ├── dean_distribution_tab.dart   ← Dean-level event management
│   └── user_qr_page.dart            ← Student QR code + active packages
│
└── components/
    └── user_avatar.dart             ← Reusable profile photo / initials widget
```

---

## Key Observations

1. **No feature-based folder structure**: Files are organised at the root `lib/` level with role prefix naming (`admin_`, `office_admin_`, `hr_admin_`, `security_admin_`, `event_admin_`, `dean_`). As the project grows, adopting a feature-folder structure (`lib/features/attendance/`, `lib/features/distribution/`) would improve navigability.

2. **`admin_home_page.dart` is the largest file** (4,036 lines, 167 KB). It bundles all L1/L2/L3 admin logic including class creation, log management, analytics, and settings. Splitting this into separate feature files would significantly improve maintainability.

3. **`distribution/` is the only feature-scoped subfolder**, indicating a more modular approach was adopted as this feature was added later.

4. **`services/` follows a clean separation** of concern — backend operations are abstracted from UI code.
