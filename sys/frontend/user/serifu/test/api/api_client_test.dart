import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/api/api_client.dart';

void main() {
  group('ApiException', () {
    test('toString formats correctly', () {
      final ex = ApiException('Not found', statusCode: 404);
      expect(ex.toString(), 'ApiException: Not found (status: 404)');
    });

    test('has correct message field', () {
      final ex = ApiException('Server error', statusCode: 500);
      expect(ex.message, 'Server error');
    });

    test('has correct statusCode field', () {
      final ex = ApiException('Bad request', statusCode: 400);
      expect(ex.statusCode, 400);
    });

    test('statusCode can be null', () {
      final ex = ApiException('Unknown error');
      expect(ex.statusCode, isNull);
      expect(ex.toString(), 'ApiException: Unknown error (status: null)');
    });
  });

  group('ApiClient token management', () {
    test('setToken and clearToken do not crash', () {
      final client = ApiClient();
      expect(() => client.setToken('test-token'), returnsNormally);
      expect(() => client.clearToken(), returnsNormally);
    });
  });

  group('ApiClient userId management', () {
    test('setUserId and userId getter', () {
      final client = ApiClient();
      expect(client.userId, isNull);
      client.setUserId('user-123');
      expect(client.userId, 'user-123');
    });
  });
}
