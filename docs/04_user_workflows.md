# 04 — User Workflows

This document describes the end-to-end workflows for each user type.

---

## Workflow 1: New Student/Employee Onboarding

```
Student opens app
  → Taps "Register" on login screen
  → Fills registration form:
       Full Name, Unique ID, Department (picker), Password, Confirm Password,
       Security Question + Answer
  → Captures selfie → App uploads photo to Appwrite Storage
  → App sends selfie + username to ML backend /register-face
       (up to 3 retries with cold-start handling)
  → App creates user document in Appwrite DB with status: "pending"
  → Admin sees pending registration in real-time (Realtime subscription)
  → Admin approves → status set to "active"
  → Student can now log in
```

---

## Workflow 2: Student Marking Attendance

```
Student opens app → Logs in → Home page loads (Realtime subscription)
  → Taps a class card → Class Detail Page
  → Taps "Mark Attendance"
  
  [Check 1 — Time Window]
  → App checks active attendance period for this class
  → If current time is within ±10 min of period, proceed; else blocked
  
  [Check 2 — Geofence] (if class has boundary)
  → App requests GPS location (high accuracy)
  → Calculates Haversine distance to boundary centre
  → If distance > radius: show error dialog, blocked
  → If within radius: proceed
  
  [Check 3 — Face Verification]
  → Camera opens (or Windows browser workaround)
  → Student captures live photo
  → Photo sent to ML backend /login-face with username
  → Backend returns {"verified": true} or error
  → If not verified: blocked
  
  [Success Path]
  → Photo uploaded to attendance_photos Appwrite Storage bucket
  → Attendance log document created with:
       username, classId, periodId, timestamp, photoUrl,
       isWithinGeofence, adminVerifiedStatus: "Pending"
  → Success message shown to student
  → Log appears in admin's real-time log feed
```

---

## Workflow 3: Admin Reviewing Attendance

```
Admin logs in → Admin portal
  → Navigates to Analytics tab
  → Views real-time feed of all attendance logs (scoped to their classes)
  → Applies date-range or class filter if needed
  → Taps a log entry to see details:
       Student name, class, timestamp, GPS status, photo
  → Updates adminVerifiedStatus to Present / Absent
  → Or enters multi-select mode → selects entries → bulk delete
  → Or exports filtered logs to CSV
```

---

## Workflow 4: Employee Submitting Leave

```
Employee logs in → Class Detail Page (or admin portal)
  → Taps "Request Leave"
  → Selects leave category (Medical / Casual / Paid / LTC)
  → Picks date range via calendar picker
  → Enters reason (up to 500 chars)
  → Taps Submit
  → App calls AdminHierarchyService.resolveApprovers()
       → Finds admin at (requester level - 1)
  → Creates leave_request document:
       userId, userName, leaveType, startDate, endDate,
       reason, status: "pending", approverLevel, approverId
  → Correct approver sees request in their leave inbox
```

---

## Workflow 5: Admin Approving Leave

```
Admin logs in → Admin portal → Settings / Leave tab
  → Sees list of pending leave requests routed to them
  → Taps a request → Reviews details (type, dates, reason)
  → Taps Approve or Reject
  → LeaveService.updateStatus() called with status + actionBy
  → Request disappears from pending; moves to history
  → Employee's request status updates to "approved" or "rejected"
```

---

## Workflow 6: Distribution Event — Full Lifecycle

```
[Dean / Event Admin]
  → Creates distribution event: title, description, location, date
  → Status: draft
  → Adds recipients (individually or by Excel import)
  → Assigns scanner admins (from admin user list)
  → Activates event → status: active

[Scanner Admin — On Distribution Day]
  → Opens Event Admin portal → Kiosk tab
  → Selects active event from dropdown
  → Camera scanner opens (mobile_scanner)
  → Student presents QR code from their "My QR Code" page
  → Scanner reads encoded username from QR
  → App calls DistributionService.processScan():
       → Checks event is active
       → Checks admin is authorised
       → Checks student is in recipient list
       → If all pass: marks recipient status as "issued", records issuedAt, issuedBy
       → If duplicate: returns "already issued" warning
       → If not in list: returns "not eligible" warning
  → All scan attempts logged in distribution_scan_logs

[Student — After Collection]
  → Opens "My QR Code" page
  → Sees active packages section showing issued status
  → Taps "Got it" → acknowledgeReceipt() called
  → Status changes to "acknowledged" with acknowledgedAt timestamp
```

---

## Workflow 7: Security Admin Investigating Anomaly

```
Security Admin logs in → Security Admin portal
  → Selects Anomalies tab
  → Sees list of attendance logs where isWithinGeofence = false
  → Banner shows count of violations
  → Reviews each anomaly: student name, class, timestamp, GPS status
  → Cross-references with Audit Logs tab (searchable by student/class)
  → Can navigate to Access Control tab to suspend account if needed
```

---

## Workflow 8: Forgotten Password Recovery

```
User taps "Forgot Password" on login screen
  → Step 1: Enters Unique ID
       → App fetches security question from DB
       → If no question set: "Contact your admin" message shown
  → Step 2: Answers security question
       → Case-insensitive comparison against stored answer
       → If incorrect: error shown, cannot proceed
  → Step 3: Sets new password + confirm
       → Passwords must match
       → New password hashed with SHA-256
       → DB record updated
  → User can now log in with new password
```

---

## Workflow 9: Dean Managing Admin Personnel

```
Dean taps logo 5 times on login screen → "Super Admin Portal" appears
  → Logs in with Dean credentials
  → Personnel tab loads all admins institution-wide
  → Can create new admin (any role/level)
  → Can view any admin's profile, department, leave history
  → Can approve/reject leave from L1 admins (who report to Dean)
  → Distribution tab: manage all distribution events
  → Reports tab: institution-wide attendance analytics
  → System Settings: global configuration
```
