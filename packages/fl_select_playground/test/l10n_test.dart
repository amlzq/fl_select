import 'dart:convert';
import 'dart:io';

import 'package:fl_select_playground/playground_l10n.dart';
import 'package:fl_select_playground/url_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Set<String> _keys(File f) =>
    (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>).keys
        .where((k) => !k.startsWith('@'))
        .toSet();

void main() {
  test('every language has a non-empty, unique label and locale', () {
    final labels = PlaygroundLanguage.values.map((l) => l.label).toList();
    expect(labels.every((l) => l.isNotEmpty), isTrue);
    expect(labels.toSet().length, labels.length);

    final locales = PlaygroundLanguage.values.map((l) => l.locale).toSet();
    expect(locales.length, PlaygroundLanguage.values.length);
  });

  test('Chinese variants use the agreed labels and order', () {
    final zh = PlaygroundLanguage.values
        .where((l) => l.locale.languageCode == 'zh')
        .toList();
    expect(zh, <PlaygroundLanguage>[
      PlaygroundLanguage.simplifiedChinese,
      PlaygroundLanguage.chineseTw,
      PlaygroundLanguage.chineseHk,
      PlaygroundLanguage.traditionalChinese,
    ]);
    expect(zh.map((l) => l.label), <String>[
      '简体中文',
      '中文（台灣）',
      '中文（香港）',
      '繁體中文',
    ]);
  });

  test('every language survives a URL round trip', () {
    for (final lang in PlaygroundLanguage.values) {
      final state = PlaygroundUrlState(
        params: kDefaultPlaygroundParams,
        language: lang,
        themeMode: ThemeMode.system,
      );
      final decoded = PlaygroundUrlCodec.decode(
        PlaygroundUrlCodec.toQuery(state),
        fallback: state,
      );
      expect(decoded.language, lang);
    }
  });

  test('all ARB files define the same keys as the English template', () {
    final dir = Directory('lib/l10n');
    final template = _keys(File('lib/l10n/app_en.arb'));
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.arb'),
    );
    expect(files.length, greaterThanOrEqualTo(13));
    for (final f in files) {
      expect(_keys(f), template, reason: f.path);
    }
  });
}
