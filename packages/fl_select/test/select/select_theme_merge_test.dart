import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);

Future<SelectThemeData> _resolve(
  WidgetTester tester, {
  required SelectThemeData outer,
  required SelectThemeData inner,
}) async {
  late SelectThemeData seen;
  await tester.pumpWidget(
    MaterialApp(
      home: SelectTheme(
        data: outer,
        child: SelectTheme.merge(
          data: inner,
          child: Builder(
            builder: (context) {
              seen = SelectTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return seen;
}

void main() {
  final base = ThemeData.light();

  group('SelectTheme.merge', () {
    testWidgets('keeps ambient component fields the inner theme leaves null', (
      tester,
    ) async {
      final theme = await _resolve(
        tester,
        outer: SelectThemeData(
          base,
          listTileTheme: const SelectListTileTheme(
            textColor: _red,
            tileColor: _green,
          ),
          counterTheme: const SelectCounterTheme(valueColor: _red),
        ),
        inner: SelectThemeData(
          base,
          listTileTheme: const SelectListTileTheme(tileColor: _blue),
        ),
      );

      expect(theme.listTileTheme.textColor, _red);
      expect(theme.listTileTheme.tileColor, _blue);
      expect(theme.counterTheme.valueColor, _red);
    });

    testWidgets('merges panelTheme field by field', (tester) async {
      final theme = await _resolve(
        tester,
        outer: SelectThemeData(
          base,
          panelTheme: const SelectPanelTheme(elevation: 4, shadowColor: _red),
        ),
        inner: SelectThemeData(
          base,
          panelTheme: const SelectPanelTheme(shadowColor: _blue),
        ),
      );

      expect(theme.panelTheme.elevation, 4);
      expect(theme.panelTheme.shadowColor, _blue);
    });

    testWidgets('merges the cascading and skeleton themes', (tester) async {
      final theme = await _resolve(
        tester,
        outer: SelectThemeData(
          base,
          cascadingViewTheme: const SelectCascadingViewTheme(
            startBackgroundColor: _red,
          ),
          skeletonViewTheme: const SelectSkeletonViewTheme(color: _red),
        ),
        inner: SelectThemeData(
          base,
          cascadingViewTheme: const SelectCascadingViewTheme(
            endBackgroundColor: _blue,
          ),
        ),
      );

      expect(theme.cascadingViewTheme.startBackgroundColor, _red);
      expect(theme.cascadingViewTheme.endBackgroundColor, _blue);
      expect(theme.skeletonViewTheme.color, _red);
    });

    testWidgets('still replaces the non-nullable colors as a whole', (
      tester,
    ) async {
      final theme = await _resolve(
        tester,
        outer: SelectThemeData(base, selectedColor: _red),
        inner: SelectThemeData(base, backgroundColor: _blue),
      );

      expect(theme.backgroundColor, _blue);
      // Documented limitation: the inner data already carries the Material
      // default for `selectedColor`, so it overrides the ambient red.
      expect(theme.selectedColor, base.colorScheme.primary);
    });

    testWidgets('returns the child untouched when data is null', (
      tester,
    ) async {
      const child = SizedBox.shrink();
      expect(SelectTheme.merge(child: child), same(child));
    });
  });
}
