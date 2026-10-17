# 10 — Authentication & Authorization

## Authentication Model

upasthiti implements a **custom credential-based authentication system** built on top of Appwrite's Databases SDK. It does not use Appwrite's built-in Auth service (`Account` API). Instead, user credentials are stored in a `users` collection and verified client-side.

---

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant AppwriteDB as Appwrite DB
    participant MLAPI as ML Backend

    User->>App: Enter username + password
    App->>AppwriteDB: listDocuments(users, Query.equal('username', id))
    AppwriteDB-->>App: User document
    App->>App: verifyPassword(input, storedValue)
    
    alt Password verified
        App->>App: Derive admin type from role/level/department
        App->>App: Reject if status == 'disabled'
        App->>AppwriteDB: updateDocument(lastLogin = now)
        App-->>User: Navigate to home
    else Password failed
        App-->>User: Show error
    end
```

---

## Password Security

### SHA-256 Hashing
All new passwords are hashed using SHA-256 (via the Dart `crypto` package) before being stored. The hash is produced from the UTF-8 encoding of the plaintext and stored as a 64-character hex string.

### Dual-Mode Verifier
`AppwriteService.verifyPassword(inputPlaintext, storedValue)` implements a dual-mode check:
1. If `storedValue` matches the regex `^[a-f0-9]{64}$` (i.e., is a SHA-256 hash), the input is hashed and compared.
2. If `storedValue` does not match the pattern (plaintext legacy account), the raw input is compared directly.

On successful login with a plaintext password, the system immediately upgrades the stored value to a hash — enabling transparent, zero-downtime migration from plaintext to hashed credentials.

---

## Admin Login CAPTCHA

Before an admin login attempt is submitted, the user must type a randomly generated 5-character alphanumeric CAPTCHA (ambiguous characters such as `0/O/1/I` are excluded). It is regenerated on page load and after every failed attempt, and can be refreshed manually. It applies to every admin type, including the Dean.

---

## Session Management

upasthiti does not use HTTP sessions, JWT tokens, or cookies. After a successful login, the app navigates to the role-appropriate home page and holds the authenticated user's `username`, `name`, `role`, `level`, and `department` in the page widget's local state. Logout clears the navigation stack back to the login page.

There is no persistent session storage (no `shared_preferences` or secure storage). Closing and reopening the app requires re-authentication.

---

## Role-Based Access Control (RBAC)

### Single Admin Login
Every admin (Dean, L1/L2/L3, Event, and department admins) signs in through the same `AdminLoginPage`, reached from the **ADMIN** button on the main login screen. There is no portal or level selector. After the credentials are verified, the account's own record decides the dashboard (`adminKindOf` in `lib/services/admin_roles.dart`):

| Record | Dashboard |
|---|---|
| `role == 'dean'` | `DeanHomePage` |
| `role == 'admin'`, department is academic (or empty) | `AdminHomePage` at the account's `level` (1-3) |
| `role == 'admin'`, `department == 'Office'` | `OfficeAdminHomePage` |
| `role == 'admin'`, `department == 'HR'` | `HrAdminHomePage` |
| `role == 'admin'`, `department == 'Security'` | `SecurityAdminHomePage` |
| `role == 'admin'`, `department == 'Finance'` (or another functional department) | `DepartmentAdminHomePage` (placeholder) |
| `role == 'eventAdmin'` | `EventAdminHomePage` |
| anything else | rejected: "This account doesn't have admin access." |

Office, HR, Security and Finance are *functional departments*: ordinary admins with no `level`, whose power comes from `department`. Each admin holds one such role.

**Legacy accounts.** Documents with `role` of `officeAdmin`, `hrAdmin` or `securityAdmin` are still recognised. On their next login they are rewritten to `role: 'admin'`, `department: 'Office' | 'HR' | 'Security'`, `level: null`.

### Student Login Rejection of Admin Roles
The standard employee login screen rejects every account that is an admin type (`adminKindOf(data) != AdminKind.notAdmin`: Dean, any `admin`, Event and legacy special roles), displaying "Unauthorized access. Use the correct portal."

### Inactive Account Gate
Users with `status == 'pending'` cannot log in. They see a message explaining their account is awaiting admin approval.

---

## Authorization Model

Authorization is enforced at the query level. Every data fetch is scoped to what the logged-in user is permitted to see:

| Role | Data Scope |
|---|---|
| Student | Only classes they are enrolled in; only their own attendance logs |
| L3 Admin | Only classes they created; only logs from those classes |
| L2 Admin | Classes assigned via hierarchy; their department's users |
| L1 Admin | All classes for all admins in their institution |
| Office Admin | All students in their department |
| HR Admin | Leave requests in their department |
| Security Admin | All attendance logs institution-wide |
| Dean | All data institution-wide |

**Note**: This scoping is enforced by the application-level queries. Appwrite's collection-level permissions are not documented in the codebase — it is unknown whether Appwrite-level permission rules provide an additional enforcement layer.

---

## Security Question Recovery

The forgot password flow authenticates the user through their security question without requiring admin involvement:

1. User provides their Unique ID.
2. `securityQuestion` is fetched from the database (not sensitive — questions are pre-defined).
3. User provides their answer. The app checks `doc.data['securityAnswer'].toLowerCase() == inputAnswer.toLowerCase()`.
4. If correct, the user can set a new password.

**Weakness**: The security answer is stored in plaintext in the database. This is a known limitation — a future improvement would be to hash the answer as well.

---

## Authentication Audit

Every successful login writes the current UTC timestamp to `lastLogin` on the user document. This enables:
- The inactive account cleanup routine to identify and remove old accounts.
- The Security Admin's Access Control tab to display last-seen information per user.
