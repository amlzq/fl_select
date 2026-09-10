import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _amber = Color(0xFFECC104);
const _ambientPadding = EdgeInsets.fromLTRB(1, 2, 3, 4);

Set<SelectEntry> get _flatEntries => {
      SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
    };

Widget _panelHarness({
  SelectChipBarTheme? delegateChipBarTheme,
  SelectThemeData? selectTheme,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectPanel(
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          chipBarTheme: delegateChipBarTheme,
        ),
        selectTheme: selectTheme,
      ),
    ),
  );
}

void main() {
  group('SelectChipBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectChipBarTheme(chipColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectChipBarTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
      );
      final merged = base.merge(
        const SelectChipBarTheme(selectedChipColor: _amber),
      );
      expect(merged.selectedChipColor, _amber);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.padding, _ambientPadding);
      expect(merged.variant, isNull);
    });
  });

  group('SelectPanel chipBarTheme injection', () {
    testWidgets('delegate chipBarTheme.backgroundColor styles the wrap view',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        delegateChipBarTheme: const SelectChipBarTheme(backgroundColor: _amber),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == _amber),
        findsOneWidget,
      );
    });

    testWidgets('delegate theme merges field-wise over the ambient theme',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        delegateChipBarTheme: const SelectChipBarTheme(backgroundColor: _amber),
        selectTheme: SelectThemeData(
          ThemeData.light(),
          chipBarThemeData: const SelectChipBarTheme(padding: _ambientPadding),
        ),
      ));
      await tester.pumpAndSettle();

      // The delegate's backgroundColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.color == _amber &&
              w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        selectTheme: SelectThemeData(
          ThemeData.light(),
          chipBarThemeData:
              const SelectChipBarTheme(backgroundColor: Colors.teal),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == Colors.teal,
        ),
        findsOneWidget,
      );
    });
  });
}
