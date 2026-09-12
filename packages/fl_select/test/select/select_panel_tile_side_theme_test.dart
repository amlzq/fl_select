import 'package:fl_select/fl_select.dart' hide SelectPanel;
import 'package:fl_select/src/select/select_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _amber = Color(0xFFECC104);
const _ambientPadding = EdgeInsets.fromLTRB(1, 2, 3, 4);

Set<SelectEntry> get _flatEntries => {
  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
  SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
};

/// Pumps a panel whose delegate supplies the given theme overrides and
/// returns the [SelectThemeData] [SelectPanel] injected into the tree.
Future<SelectThemeData> _effectiveTheme(
  WidgetTester tester, {
  SelectThemeData? selectTheme,
  SelectGridTileTheme? gridTileTheme,
  SelectFieldTileTheme? fieldTileTheme,
  SelectSideBarTheme? sideBarTheme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectPanel(
          delegate: WrapSelectDelegate(
            selectionMode: SelectionMode.multiple,
            entries: _flatEntries,
            gridTileTheme: gridTileTheme,
            fieldTileTheme: fieldTileTheme,
            sideBarTheme: sideBarTheme,
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
  group('SelectGridTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectGridTileTheme(variant: SelectGridTileVariant.filled);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectGridTileTheme(
        variant: SelectGridTileVariant.filled,
        tileColor: Colors.blue,
      );
      final merged = base.merge(
        const SelectGridTileTheme(selectedTileColor: _amber),
      );
      expect(merged.selectedTileColor, _amber);
      expect(merged.variant, SelectGridTileVariant.filled);
      expect(merged.tileColor, Colors.blue);
    });
  });

  group('SelectFieldTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectFieldTileTheme(
        variant: SelectFieldTileVariant.outlined,
      );
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectFieldTileTheme(
        variant: SelectFieldTileVariant.outlined,
        textColor: Colors.blue,
      );
      final merged = base.merge(
        const SelectFieldTileTheme(selectedColor: _amber),
      );
      expect(merged.selectedColor, _amber);
      expect(merged.variant, SelectFieldTileVariant.outlined);
      expect(merged.textColor, Colors.blue);
    });
  });

  group('SelectSideBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectSideBarTheme(width: 120);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectSideBarTheme(width: 120, backgroundColor: Colors.blue);
      final merged = base.merge(const SelectSideBarTheme(width: 88));
      expect(merged.width, 88);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.selectedColor, isNull);
    });
  });

  group('SelectPanel theme injection (delegate merges over ambient)', () {
    testWidgets('gridTileTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          gridTileTheme: const SelectGridTileTheme(tileColor: Colors.blue),
        ),
        gridTileTheme: const SelectGridTileTheme(
          variant: SelectGridTileVariant.outlined,
        ),
      );
      expect(theme.gridTileTheme.variant, SelectGridTileVariant.outlined);
      expect(theme.gridTileTheme.tileColor, Colors.blue);
    });

    testWidgets('fieldTileTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          fieldTileTheme: const SelectFieldTileTheme(textColor: Colors.blue),
        ),
        fieldTileTheme: const SelectFieldTileTheme(
          variant: SelectFieldTileVariant.outlined,
        ),
      );
      expect(theme.fieldTileTheme.variant, SelectFieldTileVariant.outlined);
      expect(theme.fieldTileTheme.textColor, Colors.blue);
    });

    testWidgets('sideBarTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          sideBarTheme: const SelectSideBarTheme(padding: _ambientPadding),
        ),
        sideBarTheme: const SelectSideBarTheme(width: 88),
      );
      expect(theme.sideBarTheme.width, 88);
      expect(theme.sideBarTheme.padding, _ambientPadding);
    });
  });
}
