import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _shapeA = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
);
const _shapeB = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(24)),
);

void main() {
  group('SelectPanelTheme', () {
    test('copyWith replaces only non-null fields', () {
      const base = SelectPanelTheme(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
      );
      final copy = base.copyWith(shape: _shapeA);
      expect(copy.elevation, 1);
      expect(copy.shape, _shapeA);
      expect(copy.clipBehavior, Clip.antiAlias);
      expect(copy.shadowColor, isNull);
    });

    test('lerp interpolates elevation, colors and shape', () {
      const a = SelectPanelTheme(
        elevation: 0,
        shadowColor: Color(0x00000000),
        surfaceTintColor: Color(0x00000000),
        shape: _shapeA,
        clipBehavior: Clip.none,
      );
      const b = SelectPanelTheme(
        elevation: 10,
        shadowColor: Color(0xff000000),
        surfaceTintColor: Color(0xffffffff),
        shape: _shapeB,
        clipBehavior: Clip.antiAlias,
      );
      final mid = SelectPanelTheme.lerp(a, b, 0.5);
      expect(mid.elevation, 5);
      // Flutter convention: at t >= 0.5 the end value wins.
      expect(mid.clipBehavior, Clip.antiAlias);
      final quarter = SelectPanelTheme.lerp(a, b, 0.25);
      expect(quarter.clipBehavior, Clip.none);
      final end = SelectPanelTheme.lerp(a, b, 1);
      expect(end.elevation, 10);
      expect(end.clipBehavior, Clip.antiAlias);
    });

    test('lerp returns identical non-null theme when a and b are identical',
        () {
      const a = SelectPanelTheme(elevation: 4);
      expect(SelectPanelTheme.lerp(a, a, 0.3), same(a));
    });

    test('equality and hashCode', () {
      const a = SelectPanelTheme(elevation: 2, shape: _shapeA);
      const b = SelectPanelTheme(elevation: 2, shape: _shapeA);
      const c = SelectPanelTheme(elevation: 3, shape: _shapeA);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('SelectThemeData.panelTheme', () {
    test('default is a const SelectPanelTheme', () {
      final theme = SelectThemeData(ThemeData.light());
      expect(theme.panelTheme, const SelectPanelTheme());
    });

    test('copyWith and lerp propagate panelTheme', () {
      const themeA = SelectPanelTheme(elevation: 0);
      const themeB = SelectPanelTheme(elevation: 8, shape: _shapeB);
      final dataA = SelectThemeData(ThemeData.light(), panelTheme: themeA);
      final dataB = SelectThemeData(ThemeData.light(), panelTheme: themeB);

      final copied = dataA.copyWith(panelTheme: themeB);
      expect(copied.panelTheme, themeB);

      final lerped = SelectThemeData.lerp(dataA, dataB, 1)!;
      expect(lerped.panelTheme.elevation, 8);
    });

    testWidgets('SelectView renders Material when decorated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _EmptyDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                panelTheme: const SelectPanelTheme(
                  elevation: 6,
                  shape: _shapeA,
                  clipBehavior: Clip.antiAlias,
                ),
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The Scaffold itself provides a background Material (elevation 0), so
      // filter for the panel's elevated Material specifically.
      final panelMaterial = find.byWidgetPredicate(
        (w) => w is Material && w.elevation > 0,
      );
      expect(panelMaterial, findsOneWidget);
      expect(
        tester.widget<Material>(panelMaterial).elevation,
        6,
      );
    });

    testWidgets('SelectView falls back to ColoredBox when undecorated',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _EmptyDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // No elevated (decorated) Material should be present for the panel.
      expect(
        find.byWidgetPredicate((w) => w is Material && w.elevation > 0),
        findsNothing,
      );
      // The Scaffold also contributes a transparent ColoredBox, so filter for
      // the panel's own (opaque) ColoredBox background specifically.
      final panelColoredBox = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color.a == 1.0,
      );
      expect(panelColoredBox, findsOneWidget);
    });

    testWidgets('delegate.panelTheme is applied without a selectTheme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _EmptyDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                panelTheme: const SelectPanelTheme(
                  elevation: 4,
                  shape: _shapeB,
                ),
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panelMaterial = find.byWidgetPredicate(
        (w) => w is Material && w.elevation > 0,
      );
      expect(panelMaterial, findsOneWidget);
      expect(tester.widget<Material>(panelMaterial).elevation, 4);
    });
  });
}

class _EmptyDelegate extends SelectDelegate {
  _EmptyDelegate({
    required super.entriesLoader,
    super.panelTheme,
  });

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected, {
    String searchQuery = '',
  }) =>
      const SizedBox();

  @override
  Widget buildSkeleton(BuildContext context) => const SizedBox();
}
