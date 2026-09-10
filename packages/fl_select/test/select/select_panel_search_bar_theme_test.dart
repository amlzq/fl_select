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
  SelectSearchBarTheme? delegateSearchBarTheme,
  SelectThemeData? selectTheme,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectPanel(
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          searchEnabled: true,
          searchBarTheme: delegateSearchBarTheme,
        ),
        selectTheme: selectTheme,
      ),
    ),
  );
}

void main() {
  group('SelectSearchBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectSearchBarTheme(borderRadius: 8);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectSearchBarTheme(
        padding: _ambientPadding,
        borderRadius: 8,
        iconSize: 20,
      );
      final merged = base.merge(
        const SelectSearchBarTheme(fillColor: _amber),
      );
      expect(merged.fillColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.borderRadius, 8);
      expect(merged.iconSize, 20);
      expect(merged.filled, isNull);
    });
  });

  group('SelectPanel searchBarTheme injection', () {
    testWidgets('delegate searchBarTheme.fillColor styles the search bar',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        delegateSearchBarTheme:
            const SelectSearchBarTheme(filled: true, fillColor: _amber),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SelectSearchBar), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, _amber);
    });

    testWidgets('delegate theme merges field-wise over the ambient theme',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        delegateSearchBarTheme:
            const SelectSearchBarTheme(filled: true, fillColor: _amber),
        selectTheme: SelectThemeData(
          ThemeData.light(),
          searchBarTheme: const SelectSearchBarTheme(padding: _ambientPadding),
        ),
      ));
      await tester.pumpAndSettle();

      // The delegate's fillColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectSearchBar), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, _amber);
      expect(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none',
        (tester) async {
      await tester.pumpWidget(_panelHarness(
        selectTheme: SelectThemeData(
          ThemeData.light(),
          searchBarTheme:
              const SelectSearchBarTheme(filled: true, fillColor: Colors.teal),
        ),
      ));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, Colors.teal);
    });
  });
}
