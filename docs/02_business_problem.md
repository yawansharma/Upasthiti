# 02 — Business Problem & Value Proposition

## The Problem

### Proxy Attendance
In institutions using paper registers or simple QR codes, one person can mark attendance on behalf of multiple absentees. This is the most common and costly fraud in any attendance system. Proxy attendance leads to inflated records, unjustified pay or grades, and erodes institutional trust.

### Fragmented Operations
Institutions typically manage attendance through one tool, leave through email chains or paper forms, resource distribution through spreadsheets, and institutional communication through WhatsApp groups. This fragmentation leads to:
- Lost records
- No single audit trail
- Manual duplication of data entry
- No accountability chain

### No Geographically Bounded Verification
Physical presence cannot be verified without GPS. A student can log a QR code from outside the premises. Without geofencing, attendance records are geographically unverified.

### Weak Administrative Hierarchy Support
Generic attendance apps do not model the reporting relationships between administrators. Supervisors cannot see their team's leave requests. Department heads have no aggregate view. Institutional leadership has no executive dashboard.

---

## The upasthiti Solution

### Elimination of Proxy Attendance
upasthiti breaks proxy attendance at three independent layers:

1. **Time-Bounded Sessions**: Attendance can only be marked within a configurable ±10-minute window around a session's scheduled time. Pre-marking or retroactive marking is impossible.
2. **GPS Geofencing**: The device's GPS position is verified against a circular geofence stored per-class. Out-of-boundary attempts are blocked and logged with an `isWithinGeofence: false` flag, visible to the Security Admin.
3. **AI Face Verification**: The captured live photo is sent to a remote ML service that computes a face embedding and compares it against the user's registered embedding. Face mismatches block attendance.

All three checks together make it extremely difficult for someone to fraudulently mark attendance for another person.

### Unified Platform
upasthiti consolidates:
- Attendance marking and history
- Leave request submission and approval
- Class community messaging (broadcast and DMs)
- Resource/material distribution with QR scanning
- Organisational hierarchy management
- Report generation (PDF, CSV, Excel)

### Full Audit Trail
Every attendance mark creates a permanent record including a live photo, GPS result, timestamp, class, and admin-reviewed status. The Security Admin has a dedicated portal with full log access, date-range search, and geofence anomaly detection.

### Hierarchical Leave Management
Leave requests are automatically routed to the correct approver based on the requester's level in the organisational hierarchy. Level 3 admins' leave goes to Level 2, Level 2 to Level 1, Level 1 to the Dean. No manual routing required.

---

## Business Value by Stakeholder

| Stakeholder | Value |
|---|---|
| **Institution Leadership (Dean)** | Real-time institution-wide visibility, executive control panel, no manual report consolidation |
| **HR Department** | Automated leave approval workflow, exportable HR reports, biometric enrollment tracking |
| **Operations / Office Admins** | Student-by-student attendance lookup, PDF/Excel export, biometric re-registration without IT involvement |
| **Security / Compliance** | Immutable audit log, automatic geofence anomaly detection, account access management |
| **Department Heads** | Departmental analytics, team leave approval, cross-class attendance aggregation |
| **Students / Employees** | Self-service password reset, real-time class updates, leave status tracking, distribution event notifications |
