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

Widget _panelHarness({
  SelectActionBarTheme? delegateActionBarTheme,
  SelectThemeData? selectTheme,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectPanel(
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          actionBarTheme: delegateActionBarTheme,
        ),
        selectTheme: selectTheme,
      ),
    ),
  );
}

void main() {
  group('SelectActionBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectActionBarTheme(resetFlex: 3);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectActionBarTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
        resetFlex: 3,
      );
      final merged = base.merge(
        const SelectActionBarTheme(backgroundColor: _amber),
      );
      expect(merged.backgroundColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.resetFlex, 3);
      expect(merged.applyFlex, isNull);
    });
  });

  group('SelectPanel actionBarTheme injection', () {
    testWidgets(
      'delegate actionBarTheme.backgroundColor styles the action bar',
      (tester) async {
        await tester.pumpWidget(
          _panelHarness(
            delegateActionBarTheme: const SelectActionBarTheme(
              backgroundColor: _amber,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SelectActionBar), findsOneWidget);
        expect(
          find.byWidgetPredicate((w) => w is Container && w.color == _amber),
          findsOneWidget,
        );
      },
    );

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          delegateActionBarTheme: const SelectActionBarTheme(
            backgroundColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            actionBarTheme: const SelectActionBarTheme(
              padding: _ambientPadding,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delegate's backgroundColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectActionBar), findsOneWidget);
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

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            actionBarTheme: const SelectActionBarTheme(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == Colors.teal),
        findsOneWidget,
      );
    });
  });
}
