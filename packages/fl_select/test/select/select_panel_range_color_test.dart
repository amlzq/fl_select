import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _amber = Color(0xFFECC104);
const _teal = Color(0xFF00796B);

Set<SelectEntry> get _flatEntries => {
  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
  SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
};

/// Pumps a panel whose delegate supplies the given overrides and returns the
/// [SelectThemeData] [SelectPanel] injected into the tree.
Future<SelectThemeData> _effectiveTheme(
  WidgetTester tester, {
  SelectThemeData? selectTheme,
  Color? selectedColor,
  Color? backgroundColorHigh,
  SelectRangeSliderTheme? rangeSliderTheme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectPanel(
          delegate: WrapSelectDelegate(
            selectionMode: SelectionMode.multiple,
            entries: _flatEntries,
            selectedColor: selectedColor,
            backgroundColorHigh: backgroundColorHigh,
            rangeSliderTheme: rangeSliderTheme,
          ),
          selectTheme: selectTheme,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<SelectTheme>(find.byType(SelectTheme)).data;
}

void main() {
  group('SelectRangeSliderTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectRangeSliderTheme(trackHeight: 4);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectRangeSliderTheme(trackHeight: 4, thumbRadius: 10);
      final merged = base.merge(
        const SelectRangeSliderTheme(activeTrackColor: _amber),
      );
      expect(merged.activeTrackColor, _amber);
      expect(merged.trackHeight, 4);
      expect(merged.thumbRadius, 10);
      expect(merged.endLabelStyle, isNull);
    });
  });

  group('SelectPanel rangeSliderTheme injection', () {
    testWidgets('delegate rangeSliderTheme merges over ambient', (
      tester,
    ) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          rangeSliderTheme: const SelectRangeSliderTheme(trackHeight: 4),
        ),
        rangeSliderTheme: const SelectRangeSliderTheme(thumbRadius: 12),
      );
      expect(theme.rangeSliderTheme.thumbRadius, 12);
      expect(theme.rangeSliderTheme.trackHeight, 4);
    });
  });

  group('SelectPanel loose color injection', () {
    testWidgets('delegate selectedColor overrides ambient', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(ThemeData.light(), selectedColor: _teal),
        selectedColor: _amber,
      );
      expect(theme.selectedColor, _amber);
    });

    testWidgets('ambient color applies when delegate supplies none', (
      tester,
    ) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          backgroundColorHigh: _teal,
        ),
      );
      expect(theme.backgroundColorHigh, _teal);
    });

    testWidgets('Material fallback applies when neither supplies one', (
      tester,
    ) async {
      final theme = await _effectiveTheme(tester);
      expect(theme.selectedColor, isNotNull);
    });
  });
}
