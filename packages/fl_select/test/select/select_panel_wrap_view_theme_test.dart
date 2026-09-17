import 'package:fl_select/fl_select.dart' hide SelectPanel, SelectWrapView;
import 'package:fl_select/src/select/select_panel.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
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
  SelectWrapViewTheme? delegateWrapViewTheme,
  SelectThemeData? selectTheme,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectPanel(
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          chipBarTheme: delegateChipBarTheme,
          wrapViewTheme: delegateWrapViewTheme,
        ),
        selectTheme: selectTheme,
      ),
    ),
  );
}

Finder _wrapViewContainer(Color color) =>
    find.byWidgetPredicate((w) => w is Container && w.color == color);

void main() {
  group('SelectWrapViewTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectWrapViewTheme(chipColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectWrapViewTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
      );
      final merged = base.merge(
        const SelectWrapViewTheme(selectedChipColor: _amber),
      );
      expect(merged.selectedChipColor, _amber);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.padding, _ambientPadding);
      expect(merged.variant, isNull);
    });
  });

  group('SelectWrapViewTheme.lerp', () {
    test('picks the variant of the nearer endpoint', () {
      const filled = SelectWrapViewTheme(variant: SelectChipVariant.filled);
      const outlined = SelectWrapViewTheme(variant: SelectChipVariant.outlined);

      expect(
        SelectWrapViewTheme.lerp(filled, outlined, 0.25).variant,
        SelectChipVariant.filled,
      );
      expect(
        SelectWrapViewTheme.lerp(filled, outlined, 0.75).variant,
        SelectChipVariant.outlined,
      );
    });

    test('interpolates colors', () {
      const black = SelectWrapViewTheme(backgroundColor: Colors.black);
      const white = SelectWrapViewTheme(backgroundColor: Colors.white);

      expect(SelectWrapViewTheme.lerp(black, white, 0).backgroundColor!.r, 0);
      expect(
        SelectWrapViewTheme.lerp(black, white, 0.5).backgroundColor!.r,
        0.5,
      );
      expect(SelectWrapViewTheme.lerp(black, white, 1).backgroundColor!.r, 1);
    });
  });

  group('SelectPanel wrapViewTheme injection', () {
    testWidgets('delegate wrapViewTheme.backgroundColor styles the wrap view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(_wrapViewContainer(_amber), findsOneWidget);
    });

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            wrapViewTheme: const SelectWrapViewTheme(padding: _ambientPadding),
          ),
        ),
      );
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

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            wrapViewTheme: const SelectWrapViewTheme(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_wrapViewContainer(Colors.teal), findsOneWidget);
    });

    testWidgets('wrapViewTheme wins over the legacy chipBarTheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: Colors.teal,
          ),
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_wrapViewContainer(_amber), findsOneWidget);
      expect(_wrapViewContainer(Colors.teal), findsNothing);
    });

    testWidgets('legacy chipBarTheme still reaches the wrap view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: Colors.teal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_wrapViewContainer(Colors.teal), findsOneWidget);
    });
  });

  group('SelectWrapView theme ownership', () {
    testWidgets('the wrap view resolves its own theme outside a SelectPanel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(
              ThemeData.light(),
              chipBarTheme: const SelectChipBarTheme(
                backgroundColor: Colors.teal,
              ),
            ),
            child: Scaffold(
              body: SelectWrapView(
                entries: _flatEntries.toList(),
                onChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only SelectPanel folds the legacy chipBarTheme into the wrap view
      // theme; the wrap view itself never reads SelectChipBarTheme, so an
      // ambient chip theme alone leaves its chips on their own defaults.
      expect(_wrapViewContainer(Colors.teal), findsNothing);
      expect(_wrapViewContainer(Colors.transparent), findsOneWidget);
    });
  });
}
