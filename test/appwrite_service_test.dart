import 'package:flutter_test/flutter_test.dart';
import 'package:upasthiti/services/appwrite_service.dart';

void main() {
  group('AppwriteService Tests', () {
    test('hashPassword generates consistent SHA-256 hash', () {
      final plaintext = 'password123';
      final hash1 = AppwriteService.hashPassword(plaintext);
      final hash2 = AppwriteService.hashPassword(plaintext);

      // Should be consistent
      expect(hash1, equals(hash2));
      
      // Should be 64 characters (hex encoded SHA-256)
      expect(hash1.length, equals(64));
    });

    test('isHashed identifies 64-char hex strings', () {
      final validHash = 'a' * 64; // 64 char hex
      final invalidHash1 = 'password123'; // too short
      final invalidHash2 = ('a' * 63) + 'G'; // invalid hex char

      expect(AppwriteService.isHashed(validHash), isTrue);
      expect(AppwriteService.isHashed(invalidHash1), isFalse);
      expect(AppwriteService.isHashed(invalidHash2), isFalse);
    });

    test('verifyPassword handles dual-mode matching', () {
      final plaintext = 'mySecret123';
      final hashedStored = AppwriteService.hashPassword(plaintext);

      // Test against plaintext storage (legacy)
      expect(AppwriteService.verifyPassword(plaintext, plaintext), isTrue);
      expect(AppwriteService.verifyPassword('wrong', plaintext), isFalse);

      // Test against hashed storage (new)
      expect(AppwriteService.verifyPassword(plaintext, hashedStored), isTrue);
      expect(AppwriteService.verifyPassword('wrong', hashedStored), isFalse);
    });
  });
}
