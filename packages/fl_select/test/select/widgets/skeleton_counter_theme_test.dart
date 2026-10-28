import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _a = Color(0xFF111111);
const _b = Color(0xFF999999);

Widget _host(ThemeData theme, Widget child, {SelectThemeData? select}) {
  final body = Scaffold(body: child);
  return MaterialApp(
    theme: theme,
    home: select == null ? body : SelectTheme(data: select, child: body),
  );
}

void main() {
  group('SelectSkeletonViewTheme', () {
    test('value semantics, merge and lerp', () {
      const theme = SelectSkeletonViewTheme(color: _a);
      expect(theme, const SelectSkeletonViewTheme(color: _a));
      expect(theme.hashCode, const SelectSkeletonViewTheme(color: _a).hashCode);
      expect(theme.copyWith(color: _b).color, _b);
      expect(theme.merge(null), theme);
      expect(theme.merge(const SelectSkeletonViewTheme(color: _b)).color, _b);
      expect(theme.merge(const SelectSkeletonViewTheme()), theme);
      expect(
        SelectSkeletonViewTheme.lerp(
          theme,
          const SelectSkeletonViewTheme(color: _b),
          0.5,
        ).color,
        Color.lerp(_a, _b, 0.5),
      );
    });

    testWidgets('SkeletonTile resolves widget, theme, then ColorScheme', (
      tester,
    ) async {
      Color? paintedColor() {
        final box = tester.widget<Container>(find.byType(Container).first);
        return (box.decoration as BoxDecoration).color;
      }

      final light = ThemeData.light();
      await tester.pumpWidget(
        _host(light, const SkeletonTile(height: 10, width: 10)),
      );
      expect(paintedColor(), light.colorScheme.surfaceContainerLow);

      await tester.pumpWidget(
        _host(
          light,
          const SkeletonTile(height: 10, width: 10),
          select: SelectThemeData(
            light,
            skeletonViewTheme: const SelectSkeletonViewTheme(color: _a),
          ),
        ),
      );
      expect(paintedColor(), _a);

      await tester.pumpWidget(
        _host(
          light,
          const SkeletonTile(height: 10, width: 10, color: _b),
          select: SelectThemeData(
            light,
            skeletonViewTheme: const SelectSkeletonViewTheme(color: _a),
          ),
        ),
      );
      expect(paintedColor(), _b);
    });
  });

  group('SelectCounterTheme', () {
    test('value semantics, merge and lerp', () {
      const theme = SelectCounterTheme(valueColor: _a, selectedValueColor: _b);
      expect(
        theme,
        const SelectCounterTheme(valueColor: _a, selectedValueColor: _b),
      );
      expect(theme.copyWith(valueColor: _b).valueColor, _b);
      expect(theme.copyWith().selectedValueColor, _b);
      expect(theme.merge(null), theme);
      expect(theme.merge(const SelectCounterTheme()), theme);
      expect(
        theme.merge(const SelectCounterTheme(valueColor: _b)).valueColor,
        _b,
      );
      final lerped = SelectCounterTheme.lerp(
        theme,
        const SelectCounterTheme(valueColor: _b, selectedValueColor: _a),
        0.5,
      );
      expect(lerped.valueColor, Color.lerp(_a, _b, 0.5));
      expect(lerped.selectedValueColor, Color.lerp(_b, _a, 0.5));
    });

    test('SelectThemeData carries both new themes', () {
      final data = SelectThemeData(ThemeData.light());
      expect(data.skeletonViewTheme, const SelectSkeletonViewTheme());
      expect(data.counterTheme, const SelectCounterTheme());
      final withThemes = SelectThemeData(
        ThemeData.light(),
        skeletonViewTheme: const SelectSkeletonViewTheme(color: _a),
        counterTheme: const SelectCounterTheme(valueColor: _a),
      );
      expect(withThemes, isNot(data));
      expect(withThemes.copyWith().counterTheme.valueColor, _a);
      final mid = SelectThemeData.lerp(data, withThemes, 1)!;
      expect(mid.skeletonViewTheme.color, _a);
      expect(mid.counterTheme.valueColor, _a);
    });

    testWidgets('SelectCounter value color follows the theme', (tester) async {
      final entries = [
        SelectTextEntry(id: 'any', name: 'Any'),
        SelectTextEntry(id: '1', name: '1'),
      ];
      final light = ThemeData.light();

      Color? valueColor() => tester
          .widget<Text>(
            find.descendant(
              of: find.byType(SelectCounter),
              matching: find.text('Any'),
            ),
          )
          .style
          ?.color;

      await tester.pumpWidget(
        _host(light, SelectCounter(entries: entries, onChanged: (_, _) {})),
      );
      expect(valueColor(), light.colorScheme.onSurfaceVariant);

      await tester.pumpWidget(
        _host(
          light,
          SelectCounter(entries: entries, onChanged: (_, _) {}),
          select: SelectThemeData(
            light,
            counterTheme: const SelectCounterTheme(valueColor: _a),
          ),
        ),
      );
      expect(valueColor(), _a);
    });
  });

  group('SelectSideBarTheme.resolveSelectedTileColor', () {
    testWidgets('prefers the theme token over the ColorScheme', (tester) async {
      late Color seen;
      final light = ThemeData.light();
      Widget build(SelectThemeData? select) => _host(
        light,
        Builder(
          builder: (context) {
            seen = SelectSideBarTheme.resolveSelectedTileColor(context);
            return const SizedBox.shrink();
          },
        ),
        select: select,
      );

      await tester.pumpWidget(build(null));
      expect(seen, light.colorScheme.surfaceContainerLow);

      await tester.pumpWidget(
        build(
          SelectThemeData(
            light,
            sideBarTheme: const SelectSideBarTheme(selectedTileColor: _a),
          ),
        ),
      );
      expect(seen, _a);
    });
  });
}
