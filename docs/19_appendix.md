# 19 — Appendix

## A. Appwrite Collections Reference

| Collection | ID (Name) | Primary Purpose |
|---|---|---|
| Users | `users` | All user accounts (students + all admin types) |
| Classes | `classes` | Attendance class/session groups |
| Attendance Logs | `attendance_logs` | Immutable attendance marking records |
| Leave Requests | `leave_requests` | Employee/admin leave applications |
| Community Messages | `community_messages` | Class-scoped messages (broadcast + DM) |
| Distribution Events | `distribution_events` | Resource distribution event records |
| Event Recipients | `event_recipients` | Per-student per-event distribution tracking |
| Event Admin Assignments | `event_admin_assignments` | QR scanner admin assignments per event |
| Distribution Scan Logs | `distribution_scan_logs` | Immutable QR scan attempt records |

---

## B. Appwrite Storage Buckets Reference

| Bucket | ID | Contents |
|---|---|---|
| Profile Photos | `6a2c12a500260c940843` | User selfies taken at registration |
| Attendance Photos | `attendance_photos` | Live verification photos per attendance mark |
| Community Files | `community_files` | File attachments in class community chat |

---

## C. Admin Role Reference

| Role Token | Display Name | Level Field | Portal |
|---|---|---|---|
| `student` | Student / Employee | N/A | Home Page |
| `admin` | Admin (Institution) | 1 | AdminHomePage |
| `admin` | Admin (Dept. Head) | 2 | AdminHomePage |
| `admin` | Admin (Team Leader) | 3 | AdminHomePage |
| `officeAdmin` | Office Admin | N/A | OfficeAdminHomePage |
| `eventAdmin` | Event Admin | N/A | EventAdminHomePage |
| `hrAdmin` | HR Admin | N/A | HrAdminHomePage |
| `securityAdmin` | Security Admin | N/A | SecurityAdminHomePage |
| `dean` | Super Admin | N/A | DeanHomePage |

---

## D. Leave Request Status States

| Status | Meaning |
|---|---|
| `pending` | Submitted; awaiting approver action |
| `approved` | Approver has granted the leave |
| `rejected` | Approver has denied the leave |

---

## E. Attendance Log Status States

| `adminVerifiedStatus` | Meaning |
|---|---|
| `Pending` | Submitted by student; not yet reviewed by admin |
| `Present` | Admin confirmed the student was present |
| `Verified` | Alternate form of Present (treated equivalently) |
| `Absent` | Admin marked the student as absent |

---

## F. Distribution Event Status States

| Status | Meaning |
|---|---|
| `draft` | Being configured; not visible to scanner admins |
| `active` | Open for QR scanning; recipients can view on QR page |
| `closed` | Distribution complete; no further scanning allowed |

---

## G. Distribution Recipient Status States

| Status | Meaning |
|---|---|
| `pending` | Student registered; item not yet issued |
| `issued` | QR scanned; item handed over; awaiting student acknowledgement |
| `acknowledged` | Student confirmed receipt via "Got it" |
| `revoked` | Recipient removed from event |

---

## H. Distribution Scan Actions

| Action | Meaning |
|---|---|
| `issued` | Successful distribution; item marked as issued |
| `duplicate_attempt` | Student already received item; second scan blocked |
| `ineligible` | Scanned user is not on the recipient list |
| `revoked` | Student's eligibility was revoked before scanning |
| `manual_override` | Admin manually overrode a prior status |

---

## I. Leave Types

| Type | Code |
|---|---|
| Medical Leave | `Medical` |
| Casual Leave | `Casual` |
| Paid Leave | `Paid leave` |
| LTC / Tour Leave | `LTC - tour leave` |

---

## J. Security Questions (Predefined Set)

1. What is your mother's maiden name?
2. What was the name of your first pet?
3. In what city were you born?
4. What is your favourite book?
5. What high school did you attend?

---

## K. Department / School Options (Predefined Set)

The registration page offers 8 pre-configured department options. These are hardcoded in `register_page.dart` and represent the institution's school/department structure. This list would need to be updated in code for institutions with different departmental structures.

---

## L. Geofence Boundary JSON Schema

```json
{
  "lat": 18.52043,
  "lng": 73.85674,
  "radiusMeters": 150,
  "headAdminId": "admin_user_123",
  "headAdminName": "John Doe",
  "supervisorId": "admin_user_456",
  "supervisorName": "Jane Smith"
}
```

The geographic fields (`lat`, `lng`, `radiusMeters`) and admin assignment fields (`headAdminId`, `headAdminName`, `supervisorId`, `supervisorName`) coexist in the same JSON object stored in the class `boundary` field. They are separated by `AdminHierarchyService.geoFromBoundary()` and `readAssignments()`.

---

## M. QR Code Payload Format

Distribution QR codes currently encode the student's `username` directly as a plain string. The `DistributionService.encodeQr()` method returns the username unchanged. Future versions should add HMAC signing to prevent QR code sharing.

---

## N. Key File Sizes

| File | Lines | Bytes | Notes |
|---|---|---|---|
| `admin_home_page.dart` | 4,036 | 167 KB | Largest file; candidates for splitting |
| `dean_home_page.dart` | 2,351 | 92 KB | Second largest |
| `distribution/admin_distribution_tab.dart` | 1,968 | 70 KB | Distribution admin UI |
| `hr_admin_home_page.dart` | 1,448 | 49 KB | HR Admin portal |
| `security_admin_home_page.dart` | 1,200 | 40 KB | Security Admin portal |
| `services/admin_hierarchy_service.dart` | 507 | 16 KB | Hierarchy logic |
| `services/distribution_service.dart` | 493 | 15 KB | Distribution CRUD |
