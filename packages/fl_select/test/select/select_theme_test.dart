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
  group('SelectTheme.merge', () {
    testWidgets('keeps ambient component fields the inner theme leaves null', (
      tester,
    ) async {
      final theme = await _resolve(
        tester,
        outer: SelectThemeData(
          listTileTheme: const SelectListTileTheme(
            textColor: _red,
            tileColor: _green,
          ),
          counterTheme: const SelectCounterTheme(valueColor: _red),
        ),
        inner: SelectThemeData(
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
          panelTheme: const SelectPanelTheme(elevation: 4, shadowColor: _red),
        ),
        inner: SelectThemeData(
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
          cascadingViewTheme: const SelectCascadingViewTheme(
            startBackgroundColor: _red,
          ),
          skeletonViewTheme: const SelectSkeletonViewTheme(color: _red),
        ),
        inner: SelectThemeData(
          cascadingViewTheme: const SelectCascadingViewTheme(
            endBackgroundColor: _blue,
          ),
        ),
      );

      expect(theme.cascadingViewTheme.startBackgroundColor, _red);
      expect(theme.cascadingViewTheme.endBackgroundColor, _blue);
      expect(theme.skeletonViewTheme.color, _red);
    });

    testWidgets('keeps an ambient color the inner theme leaves unset', (
      tester,
    ) async {
      final theme = await _resolve(
        tester,
        outer: const SelectThemeData(
          selectedColor: _red,
          onSelectedColor: _green,
        ),
        inner: const SelectThemeData(backgroundColor: _blue),
      );

      expect(theme.selectedColor, _red);
      expect(theme.onSelectedColor, _green);
      expect(theme.backgroundColor, _blue);
    });

    testWidgets('lets the inner theme override an ambient color and control '
        'theme', (tester) async {
      const radio = RadioThemeData(splashRadius: 12);
      final theme = await _resolve(
        tester,
        outer: const SelectThemeData(
          selectedColor: _red,
          radioTheme: RadioThemeData(splashRadius: 4),
        ),
        inner: const SelectThemeData(selectedColor: _blue, radioTheme: radio),
      );

      expect(theme.selectedColor, _blue);
      expect(theme.radioTheme, radio);
    });

    testWidgets('resolves unset colors from the current Material theme', (
      tester,
    ) async {
      late BuildContext seen;
      Widget build(ThemeData theme) => MaterialApp(
        theme: theme,
        home: SelectTheme(
          data: const SelectThemeData(),
          child: Builder(
            builder: (context) {
              seen = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(build(ThemeData.light()));
      expect(
        SelectTheme.selectedColorOf(seen),
        ThemeData.light().colorScheme.primary,
      );

      await tester.pumpWidget(build(ThemeData.dark()));
      await tester.pumpAndSettle();
      expect(
        SelectTheme.selectedColorOf(seen),
        ThemeData.dark().colorScheme.primary,
      );
    });

    testWidgets('returns the child untouched when data is null', (
      tester,
    ) async {
      const child = SizedBox.shrink();
      expect(SelectTheme.merge(child: child), same(child));
    });
  });
}
