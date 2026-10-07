# 18 — Future Improvements & Roadmap

The following recommendations are derived from code analysis. Items are classified by priority.

---

## P0 — Critical (Production Readiness)

### Move Business Logic Server-Side
Currently, all attendance validation (time window, geofence, face verification) runs client-side. A modified APK could theoretically bypass all checks. **Recommendation**: Implement an Appwrite Function that validates attendance submissions server-side before writing the log record.

### Upgrade ML Backend Hosting
The Hugging Face Spaces deployment has no SLA, cold starts, and uncertain persistence. **Recommendation**: Migrate the face recognition service to a dedicated GPU instance or a managed ML inference platform (AWS SageMaker Endpoints, Google Vertex AI, or a self-hosted FastAPI/Triton server).

### Add Error Monitoring
There is no crash reporting. Production errors are invisible. **Recommendation**: Integrate Firebase Crashlytics or Sentry for automatic crash and error reporting.

### Implement Environment Configuration
Project IDs and API endpoints are hardcoded. **Recommendation**: Use `--dart-define` build arguments or a `.env` generation step to separate development, staging, and production configurations.

---

## P1 — High Priority (Security & Reliability)

### Hash Security Answers
Security question answers are stored in plaintext. **Recommendation**: Apply PBKDF2 or bcrypt hashing to security answers before storage.

### Add Server-Side Rate Limiting
The CAPTCHA is client-side only. **Recommendation**: Implement rate limiting via Appwrite Functions or a WAF to limit login attempts per IP/username.

### HMAC-Sign QR Codes
Distribution QR codes currently encode raw usernames. A screenshot of a QR can be shared for proxy collection. **Recommendation**: Sign QR payloads with an HMAC (keyed hash) that includes a short expiry timestamp, making stale or shared QR codes invalid.

### Replace `studentIds` Array with Junction Collection
The array-based enrollment pattern hits Appwrite document size limits at scale. **Recommendation**: Create a `class_enrollments` collection with one document per student-class pair.

### Add CI/CD Pipeline
No automated build or test pipeline exists. **Recommendation**: Implement GitHub Actions workflows for:
- Lint checks on every PR
- Automated APK/AAB build on merge to main
- Automated test execution

---

## P2 — Important (Feature Enhancements)

### Push Notifications
Currently, leave approvals and new class notifications rely on Appwrite Realtime (WebSocket), which requires the app to be open. **Recommendation**: Integrate Firebase Cloud Messaging (FCM) for push notifications that reach users when the app is closed.

### Biometric / PIN Lock
After a session starts, the app has no re-authentication check for sensitive admin actions. **Recommendation**: Add biometric re-authentication (fingerprint/FaceID) for high-sensitivity operations (delete logs, approve registrations).

### Offline Mode
There is no offline capability. Users with poor connectivity cannot mark attendance. **Recommendation**: Implement local-first attendance queuing using `sqflite` or `Hive`, syncing when connectivity is restored (requires server-side duplicate detection).

### Multi-Tenant Support
The application serves a single institution per deployment. **Recommendation**: Add an `institutionId` field to all collections and a top-level institution selector to support multiple independent organisations on one Appwrite project.

### Attendance Period Scheduling
Currently, admins create periods manually. **Recommendation**: Allow admins to set recurring schedules (e.g., Mon/Wed/Fri 9:00–10:00) that automatically create periods.

### Report Scheduling
Reports are generated on-demand. **Recommendation**: Allow admins to schedule weekly/monthly reports that are automatically generated and emailed.

---

## P3 — Nice to Have (UX & Analytics)

### Student Attendance Percentage Widget
Display a visual percentage indicator (pie chart or ring chart) on the student home page showing overall attendance rate.

### Admin Dashboard Analytics Charts
Replace the plain list-based analytics with interactive bar/line charts (using `fl_chart` or `syncfusion_flutter_charts`) for attendance trends over time.

### Dark Mode Toggle for Students
The student portal currently forces a dark theme. A user-toggleable light/dark mode would improve accessibility.

### Notification Preferences
Allow users to configure which events they want to be notified about (new messages, leave decisions, class invitations).

### In-App Feedback / Bug Reporting
A built-in feedback form would help the development team receive bug reports from field users.

### Export Scheduling and Auto-Email
Allow HR and Office Admins to schedule automatic weekly/monthly export emails (requires an email service integration, e.g., SendGrid via Appwrite Functions).

### Attendance Calendar View
A month-view calendar displaying attendance status per day for each student, providing a more intuitive historical view than a scrolling list.

---

## Technical Debt

| Item | Location | Effort |
|---|---|---|
| `admin_home_page.dart` is 4,000+ lines | `lib/admin_home_page.dart` | Medium — split into feature files |
| Hardcoded department list (8 options) | `register_page.dart` | Small — make configurable per institution |
| No error telemetry | Entire app | Small — add Sentry/Crashlytics |
| Double-storage of admin assignments (boundary JSON + top-level fields) | `admin_hierarchy_service.dart` | Medium — unify storage to top-level fields |
| `_kDb` constant duplicated across multiple files | Multiple admin pages | Small — reference `AppwriteService.databaseId` everywhere |
| Plaintext security answers | `profile_page.dart`, `forgot_password_page.dart` | Small — add hashing |
| No loading skeleton on initial page fetch | Multiple screens | Small — add shimmer loading states |
