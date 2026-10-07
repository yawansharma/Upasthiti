# 01 — Project Overview

## Product Name
**upasthiti**

*Tagline: Secure, Smart, Verified.*

## Developing Organisation
**Navonmesh Samadhan LLP**

## Version
`0.1.0` (as declared in `pubspec.yaml`)

---

## What Is upasthiti?

upasthiti is a cross-platform institutional management platform built with Flutter. It digitises the end-to-end lifecycle of employee/student attendance, leave management, resource distribution, and institutional governance for organisations of any size — schools, universities, corporate departments, or training institutes.

The product is distinguished from generic attendance systems by three core differentiators:

1. **AI Face Verification**: Every attendance mark is verified against the user's registered biometric face embedding, hosted on a dedicated ML inference backend.
2. **GPS Geofencing**: Each class or session can optionally enforce a geographic boundary. Users outside that boundary are blocked from marking attendance.
3. **Deep Hierarchical Administration**: Eight distinct admin roles, structured across three hierarchical levels plus four cross-cutting specialist roles, provide granular, auditable control over every part of the system.

---

## Target Users

| User Type | Description |
|---|---|
| **Students / Employees** | The primary end-users who mark attendance, submit leave requests, participate in class communities, and collect distributed resources. |
| **Team Leaders (L3 Admins)** | Manage individual classes, run attendance sessions, and review class-level logs. |
| **Heads of Department (L2 Admins)** | Oversee departments, approve team-leader leave, and access cross-class analytics. |
| **Institution Admins (L1 Admins)** | Full institutional oversight, class creation, cross-department reporting. |
| **Office Admins** | Operational role focused on student biometrics, per-student attendance records, and report generation. |
| **Event Admins** | Manage institutional events and distribution events; operate the QR-based distribution kiosk. |
| **HR Admins** | Manage leave approvals, employee registration approvals, and HR reporting. |
| **Security Admins** | Monitor audit trails, detect geofence anomalies, and manage account access control. |
| **Dean (Super Admin)** | Executive-level, institution-wide control over all admins, all classes, distribution, and system settings. |

---

## Platform Support

- **Mobile**: Android and iOS (via Flutter)
- **Desktop**: Windows (via Flutter desktop; Windows-specific workarounds for camera and multi-window are implemented)

---

## Business Problem Solved

Traditional attendance systems rely on paper registers, manual sign-ins, or simple QR codes — all of which are susceptible to proxy attendance (one person marking for another). upasthiti eliminates proxy attendance through a mandatory, multi-layered verification chain: time window → GPS location → AI face recognition → photo upload. Every successful mark creates an immutable, photo-linked audit record.

Beyond attendance, the platform consolidates leave management, institutional communication, resource distribution tracking, and organisational hierarchy management into a single application — replacing a fragmented set of spreadsheets, email threads, and paper forms.
