# 06 — Frontend Architecture

## Framework
Flutter (Dart, SDK `^3.10.4`). The application targets Android, iOS, and Windows.

---

## UI Design System

### Theme Tokens (`app_theme.dart`)
All colours, text styles, and decoration objects are centralised in `AppTheme`. Key tokens:

| Token | Value | Usage |
|---|---|---|
| `kDark` | `#101010` | Page backgrounds |
| `kGreen` | `#6A8A73` | Primary accent (buttons, active states) |
| `kPanel` | `#1A1C29` | Dark panel surfaces |
| `bottomSheet` | BoxDecoration | White card with top border radius 35 |
| `sheetHandle` | Widget | Drag handle pill for bottom sheets |
| `sectionTitle` | TextStyle | Bold section headers |
| `subheadingGrey` | TextStyle | Muted secondary text |
| `inputDecoration()` | Function | Unified text field decoration factory |

### Typography
All text uses `GoogleFonts.poppins()`. Font weights used: Regular (400), SemiBold (600), Bold (700). Font sizes range from 10 px (badges) to 28 px (page titles).

### Colour Accents by Role
Each admin role uses a unique accent colour to visually identify the portal:

| Role | Accent Hex |
|---|---|
| Standard Admin | `#6A8A73` (green) |
| Office Admin | `#8A6A6A` (rose) |
| Event Admin | `#3D6B8A` (steel blue) |
| HR Admin | `#8A7A2A` (gold-olive) |
| Security Admin | `#8A2A2A` (deep red) |
| Dean | `#D4AF37` (gold) |

---

## Component Architecture

### `UserAvatar` Component
A reusable widget (`components/user_avatar.dart`) that:
- Shows the user's profile photo from Appwrite Storage if `profilePictureId` is provided.
- Falls back to an initials circle (first letter of name) with configurable `backgroundColor` and `foregroundColor`.
- Used across all admin portals, org chart, community chat, and the student profile page.

### `RisingSheet` Component
A custom widget that wraps a scrollable bottom-sheet-style container. Used on login, registration, and most portal pages. Applies the app's signature bottom-sheet decoration (`AppTheme.bottomSheet`).

### `ClassAssignmentChips`
A row of small coloured chips showing the assigned L2 supervisor and L3 head admin on a class card. Defined in `admin_hierarchy_views.dart`.

### `L1OrganizationPanel`
A summary panel shown at the top of the Level 1 Admin's class list, displaying hierarchy statistics across all their classes.

---

## Navigation

Navigation uses Flutter's imperative Navigator with `MaterialPageRoute` and `PageRouteBuilder`. No named routes. No Router/GoRouter.

### Route Patterns
- **Push**: `Navigator.push()` — navigate forward; back button returns.
- **PushReplacement**: `Navigator.pushReplacement()` — replaces current route (login → home).
- **PushAndRemoveUntil**: Used on logout to clear the navigation stack completely back to login.

### Page Transitions
Custom page transitions are implemented via `PageRouteBuilder`:
- **Class Card → Class Management**: Slide up (y-offset 0→0) + scale (0.98→1.0) + fade.
- **Tab Switching in Admin Portal**: SlideTransition + FadeTransition (320 ms, easeOutCubic).
- **Dean Portal Tab Switching**: SlideTransition directional (left/right based on tab index comparison).

---

## State Management Pattern

All state is managed with `StatefulWidget` + `setState`. There is no external state management library. Each screen's `State` class owns its data:

```
initState()
  → fetch data from Appwrite (async)
  → subscribe to Realtime stream
  → setState() on data arrival

dispose()
  → close Realtime subscription
  → dispose TextEditingControllers
```

Data is not shared across screens via a global store. Instead, parent screens pass necessary data as constructor parameters to child screens, and child screens call `_fetchData()` on their own initiative.

---

## Platform-Specific Handling

### Windows Desktop Camera
The `image_picker` plugin's camera source does not work on Windows. The app detects `Platform.isWindows` and falls back to:
1. Launch `camera.html` (bundled asset) in the system browser via `url_launcher`.
2. Open a file gallery picker (`file_picker`) after a brief delay, allowing the user to select the photo saved from the browser camera.

### File Picker (Mobile vs Desktop)
- Mobile: `ImagePicker.pickImage(source: ImageSource.camera)` for attendance/registration.
- Desktop: `FilePicker.platform.pickFiles(type: FileType.image)`.

### Permissions
`permission_handler` is used to request `WRITE_EXTERNAL_STORAGE` on Android before generating Excel/CSV/PDF exports.

---

## Animation Summary

| Animation | Implementation | Duration |
|---|---|---|
| Splash logo appear | `ScaleTransition` + `FadeTransition`, `easeOutBack` | 1500 ms |
| Splash logo disappear | `FadeTransition` | 1000 ms |
| Login → Home crossfade | `AnimatedSwitcher` on route change | 800 ms |
| Tab switching (Admin) | `SlideTransition` + `FadeTransition` | 320 ms |
| Class card → detail | Scale + Slide + Fade (`PageRouteBuilder`) | 400 ms |
| Bottom sheets | `showModalBottomSheet` default slide | System default |
| New class notification | `AnimatedContainer` + dialog auto-dismiss | 4000 ms |

---

## Key Design Decisions

1. **No global state manager**: The codebase uses `setState` exclusively. This works because the app is screen-centric with little cross-screen data sharing. The trade-off is that some screens re-fetch data unnecessarily, but this keeps the code simple and readable.

2. **Inline StatefulBuilder in dialogs**: Create/Edit dialogs (e.g., class creation, boundary picker) use `StatefulBuilder` to hold dialog-local state without extracting a separate widget. This keeps dialog logic co-located.

3. **IndexedStack for tabs**: Several portals use `IndexedStack` with `_tabIndex` to keep tab state alive during tab switches, preventing re-fetches on every tab press.

4. **Hero tags on class cards**: Class icon and header use `Hero` widgets so that navigating from list to detail has a shared-element transition.
