import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _amber = Color(0xFFECC104);
const _ambientPadding = EdgeInsets.fromLTRB(1, 2, 3, 4);
final _ambientShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

Set<SelectEntry> get _flatEntries => {
      SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
    };

Widget _panelHarness({SelectThemeData? selectTheme}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectPanel(
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
        ),
        selectTheme: selectTheme,
      ),
    ),
  );
}

/// Pumps the harness and returns the [SelectThemeData] that [SelectPanel]
/// injected into the tree (i.e. after merging delegate-level themes).
Future<SelectThemeData> _effectiveTheme(WidgetTester tester,
    {SelectThemeData? selectTheme, required SelectDelegate delegate}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SelectPanel(delegate: delegate, selectTheme: selectTheme),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.widget<SelectTheme>(find.byType(SelectTheme)).data;
}

void main() {
  group('SelectPanelTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectPanelTheme(elevation: 4);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectPanelTheme(elevation: 4, shape: null);
      final merged = base.merge(const SelectPanelTheme(shadowColor: _amber));
      expect(merged.shadowColor, _amber);
      expect(merged.elevation, 4);
      expect(merged.clipBehavior, isNull);
    });
  });

  group('SelectTabBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectTabBarTheme(indicatorHeight: 3);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectTabBarTheme(padding: _ambientPadding);
      final merged =
          base.merge(const SelectTabBarTheme(backgroundColor: _amber));
      expect(merged.backgroundColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.indicatorColor, isNull);
    });
  });

  group('SelectListTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectListTileTheme(tileColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectListTileTheme(textColor: _amber);
      final merged =
          base.merge(const SelectListTileTheme(selectedColor: _amber));
      expect(merged.selectedColor, _amber);
      expect(merged.textColor, _amber);
      expect(merged.labelStyle, isNull);
    });
  });

  group('SelectExpansionTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectExpansionTileTheme(titlePadding: _ambientPadding);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectExpansionTileTheme(titlePadding: _ambientPadding);
      final merged =
          base.merge(const SelectExpansionTileTheme(selectedColor: _amber));
      expect(merged.selectedColor, _amber);
      expect(merged.titlePadding, _ambientPadding);
      expect(merged.animationDuration, isNull);
    });
  });

  group('SelectPanel theme injection (delegate merges over ambient)', () {
    testWidgets('panelTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          panelTheme: SelectPanelTheme(shape: _ambientShape),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          panelTheme: const SelectPanelTheme(elevation: 4),
        ),
      );
      expect(theme.panelTheme.elevation, 4);
      expect(theme.panelTheme.shape, _ambientShape);
    });

    testWidgets('tabBarTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          tabBarTheme: const SelectTabBarTheme(padding: _ambientPadding),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          tabBarTheme: const SelectTabBarTheme(backgroundColor: _amber),
        ),
      );
      expect(theme.tabBarTheme.backgroundColor, _amber);
      expect(theme.tabBarTheme.padding, _ambientPadding);
    });

    testWidgets('listTileTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          listTileTheme: const SelectListTileTheme(textColor: _amber),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          listTileTheme: const SelectListTileTheme(selectedColor: _amber),
        ),
      );
      expect(theme.listTileTheme.selectedColor, _amber);
      expect(theme.listTileTheme.textColor, _amber);
    });

    testWidgets('expansionTileTheme', (tester) async {
      final theme = await _effectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          expansionTileTheme:
              const SelectExpansionTileTheme(titlePadding: _ambientPadding),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          expansionTileTheme:
              const SelectExpansionTileTheme(selectedColor: _amber),
        ),
      );
      expect(theme.expansionTileTheme.selectedColor, _amber);
      expect(theme.expansionTileTheme.titlePadding, _ambientPadding);
    });

    testWidgets('delegate panelTheme renders an elevated Material',
        (tester) async {
      await tester.pumpWidget(_panelHarness());
      await tester.pumpAndSettle();
      // Sanity check on top of the capture-based tests above: the merged
      // panelTheme must actually reach the rendered panel decoration.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SelectPanel(
            delegate: WrapSelectDelegate(
              selectionMode: SelectionMode.multiple,
              entries: _flatEntries,
              panelTheme: const SelectPanelTheme(elevation: 6),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Material && w.elevation == 6),
        findsOneWidget,
      );
    });
  });
}
