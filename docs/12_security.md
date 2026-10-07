# 12 — Security

## Security Architecture Overview

upasthiti implements security across four layers: credential security, access control, behavioral verification, and audit logging.

---

## Layer 1: Credential Security

### Password Hashing (SHA-256)
All passwords are stored as SHA-256 hashes. The `AppwriteService.hashPassword()` method:
1. Encodes the plaintext as UTF-8 bytes.
2. Applies SHA-256 via the Dart `crypto` package.
3. Returns the hex-encoded digest (64 characters).

This means no plaintext password is ever stored or transmitted to the backend. Even if the Appwrite database were exposed, passwords would remain computationally infeasible to reverse.

### Legacy Password Migration
The dual-mode verifier (`verifyPassword`) transparently upgrades plaintext legacy passwords to SHA-256 hashes on the user's next successful login. The migration requires no user action and produces no downtime.

### Security Questions
Security questions and answers are used for password recovery. **Current limitation**: Answers are stored in plaintext. A future improvement would apply a one-way hash (e.g., PBKDF2 or bcrypt) to security answers as well.

---

## Layer 2: Access Control

### Role Enforcement at Login
Every admin portal login includes:
1. A database query for the user document.
2. A check that `doc.role == expectedRole` AND (for levelled admins) `doc.level == requiredLevel`.
3. A check that `doc.status == 'active'`.

If any check fails, the login is rejected with a specific error message.

### Dean Portal Obscurity
The Super Admin (Dean) portal is not visible in any menu. Access requires tapping the logo 5 times to reveal the button. This is a form of "security through obscurity" layered on top of the Dean's credentials — a two-factor approach where both knowledge of the gesture AND valid Dean credentials are required.

### Admin CAPTCHA
A random arithmetic CAPTCHA is required before admin credentials can be submitted. This provides a lightweight defence against automated credential-stuffing or brute-force attempts targeting admin accounts.

### Account Status Gate
Newly registered users have `status: 'pending'`. They cannot log in until an admin approves their account, setting `status: 'active'`. This prevents unapproved users from accessing any institutional data.

---

## Layer 3: Behavioral Verification (Anti-Proxy)

### Time-Bounded Attendance Windows
Attendance can only be marked within ±10 minutes of a session's scheduled period. This prevents:
- Pre-marking (marking before the session starts)
- Retroactive marking (marking after the session has ended)

### GPS Geofencing
Per-class circular geofence boundaries enforce that the student is physically present at the correct location. The Haversine formula provides accurate real-world distance calculation. Logs record `isWithinGeofence: false` for any attempt made outside the boundary — this is never silently ignored.

### AI Face Verification
A live photo is required for every attendance mark. The remote ML backend compares the photo against the user's stored face embedding. A mismatch completely blocks the attendance record.

### Combined Verification Chain
All three behavioral checks must pass for an attendance record to be created. A partial pass is treated as a failure. This creates a composite anti-fraud mechanism that is significantly harder to defeat than any single check alone.

---

## Layer 4: Audit Logging

### Attendance Log Immutability
Attendance logs (`attendance_logs` collection) are only soft-deletable (via `isHiddenFromAdmin` flag). Hard deletion is available only to Level 1 admins and the Dean. Every log retains:
- The student's username
- The exact timestamp
- The GPS verification result (`isWithinGeofence`)
- A direct link to the attendance verification photo
- The admin-reviewed status

### Photo Evidence
Each attendance mark uploads a live photo to Appwrite Storage and stores the direct view URL in the log. This provides photographic evidence for any disputed attendance record.

### Distribution Scan Logs
Every QR scan attempt (successful or not) is recorded in `distribution_scan_logs` with the scanner's ID, the student's ID, the action type, and the timestamp. This creates a complete chain of custody for distributed items.

### `lastLogin` Audit Trail
Every user's most recent login timestamp is recorded. The Security Admin's Access Control tab displays this, enabling identification of dormant accounts.

---

## Known Security Limitations

> The following are limitations inferred from code analysis. They represent areas for future improvement.

| Limitation | Risk | Recommended Improvement |
|---|---|---|
| **Client-side business logic** | A modified app could bypass geofence/time/face checks | Move critical checks to Appwrite Functions (server-side) |
| **No server-side auth tokens** | Session state held in widget memory; no token expiry | Implement Appwrite Auth + JWT sessions |
| **Security answers in plaintext** | DB exposure reveals answers | Hash security answers with PBKDF2 |
| **No rate limiting on login** | Brute-force attempts possible (CAPTCHA is only client-side) | Add server-side rate limiting via Appwrite Functions |
| **QR codes encode raw username** | QR codes can be screenshot-shared for proxy distribution | HMAC-sign QR payloads with a short expiry |
| **No error telemetry** | Security incidents may go undetected | Integrate Sentry or similar crash/error reporting |
| **No encrypted transport verification** | App trusts HTTPS but does no certificate pinning | Implement certificate pinning for production |
| **Hardcoded project IDs** | Leaked APK exposes project ID | Use obfuscation + build-time environment injection |
