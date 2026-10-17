import 'package:flutter_test/flutter_test.dart';
import 'package:upasthiti/services/admin_roles.dart';

void main() {
  group('adminKindOf', () {
    test('dean and event admin', () {
      expect(adminKindOf({'role': 'dean'}), AdminKind.dean);
      expect(adminKindOf({'role': 'eventAdmin'}), AdminKind.event);
    });

    test('hierarchy admins with academic or no department', () {
      expect(
        adminKindOf({'role': 'admin', 'level': 2, 'department': kAcademicDepartments.first}),
        AdminKind.hierarchy,
      );
      expect(adminKindOf({'role': 'admin'}), AdminKind.hierarchy);
      expect(hierarchyLevelOf({'role': 'admin'}), 1);
    });

    test('department admins resolve from department', () {
      expect(adminKindOf({'role': 'admin', 'department': 'Office'}), AdminKind.office);
      expect(adminKindOf({'role': 'admin', 'department': 'HR'}), AdminKind.hr);
      expect(adminKindOf({'role': 'admin', 'department': 'Security'}), AdminKind.security);
      expect(adminKindOf({'role': 'admin', 'department': 'Finance'}), AdminKind.otherDepartment);
    });

    test('legacy roles still resolve', () {
      final soc = kAcademicDepartments.first;
      expect(adminKindOf({'role': 'officeAdmin', 'department': soc}), AdminKind.office);
      expect(adminKindOf({'role': 'hrAdmin', 'department': soc}), AdminKind.hr);
      expect(adminKindOf({'role': 'securityAdmin'}), AdminKind.security);
    });

    test('non-admins', () {
      expect(adminKindOf({'role': 'student'}), AdminKind.notAdmin);
      expect(adminKindOf({}), AdminKind.notAdmin);
    });
  });

  group('legacyMigrationPatch', () {
    test('converts legacy roles to admin + functional department', () {
      expect(
        legacyMigrationPatch({'role': 'officeAdmin', 'department': kAcademicDepartments.first}),
        {'role': 'admin', 'department': 'Office', 'level': null},
      );
      expect(legacyMigrationPatch({'role': 'hrAdmin'})!['department'], 'HR');
      expect(legacyMigrationPatch({'role': 'securityAdmin'})!['department'], 'Security');
    });

    test('leaves other roles alone', () {
      expect(legacyMigrationPatch({'role': 'admin', 'department': 'HR'}), isNull);
      expect(legacyMigrationPatch({'role': 'eventAdmin'}), isNull);
      expect(legacyMigrationPatch({'role': 'dean'}), isNull);
    });
  });

  test('isFunctionalDept', () {
    for (final d in kFunctionalDepartments) {
      expect(isFunctionalDept(d), isTrue);
    }
    expect(isFunctionalDept(kAcademicDepartments.first), isFalse);
    expect(isFunctionalDept(null), isFalse);
  });

  test('adminLabel', () {
    expect(adminLabel({'role': 'admin', 'level': 3}), 'Team Leader');
    expect(adminLabel({'role': 'admin', 'department': 'Finance'}), 'Finance Admin');
    expect(adminLabel({'role': 'hrAdmin'}), 'HR Admin');
  });
}
