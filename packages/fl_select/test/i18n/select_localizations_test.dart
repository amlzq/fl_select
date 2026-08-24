import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectLocalizations', () {
    test('falls back to English when the language is unsupported', () {
      final localizations = SelectLocalizations(const Locale('xx'));
      expect(localizations.apply, 'Apply');
      expect(localizations.reset, 'Reset');
      expect(localizations.multiple, 'Multiple');
    });

    test('resolves labels for a full language + script match', () {
      final localizations = SelectLocalizations(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
      expect(localizations.apply, '应用');
      expect(localizations.reset, '重置');
    });

    test('prefers a region + script match over a bare language match', () {
      final localizations = SelectLocalizations(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
      expect(localizations.apply, '套用');
    });
  });
}
