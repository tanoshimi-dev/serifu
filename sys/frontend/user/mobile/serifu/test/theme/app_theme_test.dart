import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/theme/app_theme.dart';

void main() {
  group('AppTheme constants', () {
    test('primaryStart is correct color', () {
      expect(AppTheme.primaryStart, const Color(0xFF6C5CE7));
    });

    test('background is correct color', () {
      expect(AppTheme.background, const Color(0xFFF8F9FA));
    });

    test('likeRed is correct color', () {
      expect(AppTheme.likeRed, const Color(0xFFE74C3C));
    });
  });

  group('AppTheme.theme', () {
    test('returns ThemeData with useMaterial3', () {
      final theme = AppTheme.theme;
      expect(theme.useMaterial3, true);
    });

    test('has correct scaffoldBackgroundColor', () {
      final theme = AppTheme.theme;
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
    });
  });
}
