import 'package:flutter/material.dart';

/// Single source of truth for how a `users` document maps to an admin type.
///
/// Every admin signs in through the same login page; the dashboard is chosen
/// from the account's `role`, `level` and `department`:
///   * `role: 'dean'`        → super admin
///   * `role: 'eventAdmin'`  → event admin
///   * `role: 'admin'` + a functional `department` (Office / HR / Security /
///     Finance …) → department admin, no level
///   * `role: 'admin'` otherwise → L1/L2/L3 hierarchy admin
///
/// Legacy `officeAdmin` / `hrAdmin` / `securityAdmin` docs are still
/// recognised, and rewritten to the new shape on their next login
/// (see [legacyMigrationPatch]).

const List<String> kAcademicDepartments = [
  "School of Computing (SoC)",
  "School of Electrical & Electronics Engineering (SEEE)",
  "School of Mechanical Engineering (SoME)",
  "School of Civil Engineering (SoCE)",
  "School of Chemical & Biotechnology (SCBT)",
  "School of Law",
  "School of Management (SoM)",
  "School of Arts, Sciences, Humanities & Education (SASHE)",
];

/// Departments that grant an admin a functional role instead of a level.
const String kDeptOffice = 'Office';
const String kDeptHr = 'HR';
const String kDeptSecurity = 'Security';
const String kDeptFinance = 'Finance';

const List<String> kFunctionalDepartments = [
  kDeptOffice,
  kDeptHr,
  kDeptSecurity,
  kDeptFinance,
];

const List<String> kAllDepartments = [
  ...kAcademicDepartments,
  ...kFunctionalDepartments,
];

/// Every `role` value that belongs to an admin-type account, including legacy
/// values for docs that have not been migrated yet. Use this in role queries.
const List<String> kAdminRoleValues = [
  'admin',
  'eventAdmin',
  'officeAdmin',
  'hrAdmin',
  'securityAdmin',
];

const Map<String, String> _kLegacyRoleToDept = {
  'officeAdmin': kDeptOffice,
  'hrAdmin': kDeptHr,
  'securityAdmin': kDeptSecurity,
};

bool isFunctionalDept(String? dept) =>
    dept != null && kFunctionalDepartments.contains(dept);

enum AdminKind {
  dean,
  hierarchy,
  office,
  hr,
  security,
  event,
  otherDepartment,
  notAdmin,
}

AdminKind _kindForDept(String dept) {
  switch (dept) {
    case kDeptOffice:
      return AdminKind.office;
    case kDeptHr:
      return AdminKind.hr;
    case kDeptSecurity:
      return AdminKind.security;
    default:
      return AdminKind.otherDepartment;
  }
}

AdminKind adminKindOf(Map<String, dynamic> data) {
  final role = data['role'] as String?;
  switch (role) {
    case 'dean':
      return AdminKind.dean;
    case 'eventAdmin':
      return AdminKind.event;
    case 'officeAdmin':
    case 'hrAdmin':
    case 'securityAdmin':
      return _kindForDept(_kLegacyRoleToDept[role]!);
    case 'admin':
      final dept = data['department'] as String?;
      if (isFunctionalDept(dept)) return _kindForDept(dept!);
      return AdminKind.hierarchy;
    default:
      return AdminKind.notAdmin;
  }
}

bool isHierarchyAdmin(Map<String, dynamic> data) =>
    adminKindOf(data) == AdminKind.hierarchy;

/// True for Office / HR / Security / Finance… admins (new or legacy shape).
bool isDepartmentAdmin(Map<String, dynamic> data) {
  final kind = adminKindOf(data);
  return kind == AdminKind.office ||
      kind == AdminKind.hr ||
      kind == AdminKind.security ||
      kind == AdminKind.otherDepartment;
}

/// Hierarchy level (1–3) of an admin; legacy docs without a level are L1.
int hierarchyLevelOf(Map<String, dynamic> data) =>
    data['level'] is int ? data['level'] as int : 1;

/// The functional department of a department admin, resolving legacy roles.
String? functionalDeptOf(Map<String, dynamic> data) {
  final legacy = _kLegacyRoleToDept[data['role']];
  if (legacy != null) return legacy;
  final dept = data['department'] as String?;
  return isFunctionalDept(dept) ? dept : null;
}

/// Fields that convert a legacy Office/HR/Security doc to the new shape, or
/// null when the doc needs no migration.
Map<String, dynamic>? legacyMigrationPatch(Map<String, dynamic> data) {
  final dept = _kLegacyRoleToDept[data['role']];
  if (dept == null) return null;
  return {'role': 'admin', 'department': dept, 'level': null};
}

String adminLabel(Map<String, dynamic> data) {
  switch (adminKindOf(data)) {
    case AdminKind.dean:
      return 'Dean';
    case AdminKind.event:
      return 'Event Admin';
    case AdminKind.hierarchy:
      switch (data['level']) {
        case 1:
          return 'Institution Admin';
        case 2:
          return 'Head of Department';
        case 3:
          return 'Team Leader';
        default:
          return 'Admin';
      }
    case AdminKind.office:
    case AdminKind.hr:
    case AdminKind.security:
    case AdminKind.otherDepartment:
      return '${functionalDeptOf(data)} Admin';
    case AdminKind.notAdmin:
      return (data['role'] as String?) ?? 'User';
  }
}

/// Short badge text (e.g. "L2", "HR", "EA").
String adminShortLabel(Map<String, dynamic> data) {
  switch (adminKindOf(data)) {
    case AdminKind.dean:
      return 'DEAN';
    case AdminKind.event:
      return 'EA';
    case AdminKind.hierarchy:
      return 'L${hierarchyLevelOf(data)}';
    case AdminKind.office:
      return 'OA';
    case AdminKind.hr:
      return 'HR';
    case AdminKind.security:
      return 'SA';
    case AdminKind.otherDepartment:
      final dept = functionalDeptOf(data) ?? '';
      return dept.length <= 3 ? dept.toUpperCase() : dept.substring(0, 2).toUpperCase();
    case AdminKind.notAdmin:
      return '?';
  }
}

Color adminColor(Map<String, dynamic> data) {
  switch (adminKindOf(data)) {
    case AdminKind.dean:
      return const Color(0xFFD4AF37);
    case AdminKind.event:
      return const Color(0xFF3D6B8A);
    case AdminKind.office:
      return const Color(0xFF8A6A6A);
    case AdminKind.hr:
      return const Color(0xFF8A7A2A);
    case AdminKind.security:
      return const Color(0xFF8A2A2A);
    case AdminKind.otherDepartment:
      return const Color(0xFF5A6A7A);
    case AdminKind.hierarchy:
      switch (data['level']) {
        case 2:
          return const Color(0xFF4E7A8A);
        case 3:
          return const Color(0xFF6A8A73);
        default:
          return const Color(0xFF7A6A8A);
      }
    case AdminKind.notAdmin:
      return Colors.grey;
  }
}
