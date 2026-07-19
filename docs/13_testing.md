# 13 — Testing

## Current Testing Status

Based on a complete review of the repository, **no automated tests exist in the codebase** beyond the default Flutter test scaffold.

The `dev_dependencies` in `pubspec.yaml` include:
- `flutter_test` (SDK) — the Flutter testing framework
- `flutter_lints: ^6.0.0` — static analysis linting rules

No test files were found beyond the generated `test/widget_test.dart` placeholder.

---

## Linting

`flutter_lints` is configured, providing a standard set of Dart/Flutter lint rules. This enforces:
- Proper `const` usage
- `prefer_single_quotes`
- Unused variable detection
- `avoid_print` (prefer logging)
- Proper `async/await` patterns

The presence of `flutter_lints` suggests the code is at minimum linted on every build, reducing common code quality issues.

---

## Manual Testing Approach (Inferred)

Given the absence of automated tests, the team relies on manual testing. The following test scenarios would be critical based on the application's functionality:

### Authentication
- [ ] Valid login with hashed password
- [ ] Valid login with plaintext password (legacy) + verify hash upgrade
- [ ] Invalid credentials rejection
- [ ] Wrong role portal rejection
- [ ] Pending account gate
- [ ] CAPTCHA rejection
- [ ] Forgot password — correct/incorrect security answer
- [ ] Dean 5-tap secret gesture on different timings

### Attendance
- [ ] Mark attendance within time window
- [ ] Block marking outside time window
- [ ] Block marking outside geofence
- [ ] Block marking when face verification fails
- [ ] Block marking when ML service is cold (retry handling)
- [ ] Successful attendance creates correct DB document
- [ ] Photo uploaded to correct bucket

### Leave
- [ ] Leave request routed to correct approver
- [ ] Leave approved and status updated
- [ ] Leave rejected and status updated
- [ ] No approver found — error message shown

### Distribution
- [ ] Event creates as draft
- [ ] Recipients added individually and via Excel import
- [ ] QR scan marks recipient as issued
- [ ] Duplicate scan returns warning
- [ ] Non-eligible student scan returns warning
- [ ] Student acknowledgement updates status

### Admin Operations
- [ ] Class creation with geofence
- [ ] Class creation without geofence
- [ ] L2/L3 assignment to class
- [ ] Student registration approval/rejection
- [ ] Org chart renders correct hierarchy

---

## Recommended Testing Strategy

For a production-grade version of this application, the following testing pyramid is recommended:

### Unit Tests
- `AppwriteService.hashPassword()` and `verifyPassword()`
- `AdminHierarchyService.readAssignments()` with boundary JSON variants
- `AdminHierarchyService.resolveApprovers()` for various level combinations
- `DistributionService.encodeQr()` / `decodeQr()` round-trip
- `LeaveService` CRUD operations (with mock Appwrite client)

### Widget Tests
- `LoginPage` form validation and submission flow
- `LeaveRequestPage` form field validation
- `UserAvatar` rendering with and without photo ID
- `AdminLevelSelectPage` card tap navigation

### Integration Tests
- Full attendance marking flow (mock ML backend + mock Appwrite)
- Full registration flow (mock ML backend + real or mock Appwrite)
- Distribution scan flow (mock Appwrite)

### End-to-End Tests
- Flutter integration tests with a test Appwrite project
- ML backend tested with sample face images

---

## CI/CD Status

No CI/CD configuration files were found in the repository. There is no:
- GitHub Actions workflow
- Bitrise configuration
- Fastlane setup
- `Dockerfile`
- `docker-compose.yml`
- Kubernetes manifests

The project is deployed manually from the developer's machine.
