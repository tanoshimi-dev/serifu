import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/utils/time_utils.dart';

void main() {
  group('timeAgo', () {
    test('returns 秒前 for seconds', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(seconds: 30)));
      expect(result, '30秒前');
    });

    test('returns 分前 for minutes', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(minutes: 15)));
      expect(result, '15分前');
    });

    test('returns 時間前 for hours', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(hours: 5)));
      expect(result, '5時間前');
    });

    test('returns 日前 for days', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 10)));
      expect(result, '10日前');
    });

    test('returns ヶ月前 for months', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 90)));
      expect(result, '3ヶ月前');
    });

    test('returns 年前 for years', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 400)));
      expect(result, '1年前');
    });
  });
}
