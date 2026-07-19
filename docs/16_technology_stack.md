# 16 — Technology Stack

## Summary Table

| Category | Technology | Version | Role |
|---|---|---|---|
| **UI Framework** | Flutter | SDK ^3.10.4 | Cross-platform UI and application logic |
| **Language** | Dart | ^3.10.4 (implied) | Primary programming language |
| **BaaS** | Appwrite Cloud | SDK ^23.1.0 | Database, Storage, Realtime |
| **ML Inference** | Hugging Face Spaces (Python) | N/A | Remote face recognition API |
| **Map Tiles** | OpenStreetMap | N/A | Free tile source for geofence map |
| **Font** | Google Fonts (Poppins) | ^6.2.1 | Application-wide typography |
| **On-device ML** | Google ML Kit Face Detection | ^0.11.0 | Client-side face pre-validation |
| **Cryptography** | `crypto` | ^3.0.6 | SHA-256 password hashing |
| **Map Rendering** | `flutter_map` | ^8.2.2 | Interactive map widget |
| **Coordinate Math** | `latlong2` | ^0.9.1 | LatLng type for map calculations |
| **GPS** | `geolocator` | ^10.1.0 | Device location access |
| **Camera** | `camera` | ^0.11.3 | Low-level camera stream |
| **Image Picker** | `image_picker` | ^1.0.7 | Photo capture (mobile) |
| **File Picker** | `file_picker` | ^10.3.8 | Attachment + Excel import |
| **HTTP** | `http` | ^1.6.0 | Multipart HTTP calls to ML backend |
| **QR Generation** | `qr_flutter` | ^4.1.0 | Student QR code display |
| **QR Scanning** | `mobile_scanner` | ^5.2.3 | Distribution kiosk scanning |
| **Excel** | `excel` | ^4.0.6 | XLSX generation + import parsing |
| **CSV** | `csv` | ^6.0.0 | CSV export |
| **PDF** | `pdf` | ^3.12.0 | PDF report generation |
| **Print/Share** | `printing` | ^5.14.3 | PDF sharing and printing |
| **Date/Time** | `intl` | ^0.19.0 | Date formatting |
| **Path** | `path_provider` | ^2.1.5 | Device storage paths for export |
| **Permissions** | `permission_handler` | ^12.0.1 | Runtime permission requests |
| **URL Launch** | `url_launcher` | ^6.3.2 | Open URLs; Windows camera workaround |
| **WebView (Cross)** | `webview_flutter` | ^4.13.1 | In-app web content |
| **WebView (Win)** | `webview_windows` | ^0.4.0 | Windows-specific WebView |
| **Multi-Window (Win)** | `desktop_multi_window` | ^0.3.0 | Windows multi-window support |

---

## Technology Rationale

### Why Flutter?
Flutter enables a single codebase targeting Android, iOS, and Windows from one Dart codebase. For an institutional management platform that may be used on both mobile (students in field) and desktop (administrative offices), this dramatically reduces development cost and ensures feature parity across platforms.

### Why Appwrite?
Appwrite provides database, file storage, and real-time capabilities as a managed service, eliminating the need to build and host a custom backend. Its Dart SDK integrates directly with Flutter. The NoSQL document model is well-suited to the application's schema, which has schema variation between different user types.

### Why Hugging Face Spaces for ML?
Hugging Face Spaces provides free hosting for Python ML applications, making it a practical choice for an MVP or pilot deployment. The trade-off is reliability and cold starts, which the application mitigates with its retry logic. This is appropriate for a development stage product.

### Why `setState` instead of a state manager?
The application's screens are largely independent, each managing their own data. Cross-screen data sharing is limited to constructor parameters. At the current scale, `setState` is sufficient and keeps the codebase simple. As the application grows, a reactive state manager (Riverpod, BLoC, or Provider) would become beneficial for shared authentication state, global notification counters, and cross-screen data synchronisation.

### Why Custom Auth instead of Appwrite Auth?
Appwrite's built-in `Account` service provides JWT-based authentication. The application instead implements a custom username/password check against the `users` collection. This was likely chosen for simplicity and full control over the user document schema. The trade-off is losing Appwrite's built-in session management, token refresh, and multi-factor authentication capabilities.

---

## Development Tools

| Tool | Purpose |
|---|---|
| Flutter SDK | Build, run, and test the Flutter app |
| Dart SDK | Language toolchain |
| `flutter_lints` | Static analysis (lint rules) |
| `flutter_launcher_icons` | Generate platform icons from source image |
| Python 3.x | Used for `generate_detailed_doc.py` and `generate_brochure.py` (doc generation scripts, not part of the app) |
| Appwrite Console | Database schema management, storage bucket configuration |

---

## Platform Compatibility Matrix

| Feature | Android | iOS | Windows |
|---|---|---|---|
| Login | ✅ | ✅ | ✅ |
| Registration | ✅ | ✅ | ✅ (with browser camera workaround) |
| Attendance Camera Capture | ✅ | ✅ | ✅ (with browser camera workaround) |
| GPS Geofencing | ✅ | ✅ | ⚠️ (depends on Windows GPS availability) |
| QR Scanning | ✅ | ✅ | ✅ |
| Excel Export | ✅ | ✅ | ✅ |
| PDF Export | ✅ | ✅ | ✅ |
| Map (Geofence Picker) | ✅ | ✅ | ✅ |
| File Attachment (Chat) | ✅ | ✅ | ✅ |
