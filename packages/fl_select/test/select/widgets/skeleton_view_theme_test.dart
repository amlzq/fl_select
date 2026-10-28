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

    test('SelectThemeData carries it', () {
      const data = SelectThemeData();
      expect(data.skeletonViewTheme, const SelectSkeletonViewTheme());
      const withTheme = SelectThemeData(
        skeletonViewTheme: SelectSkeletonViewTheme(color: _a),
      );
      expect(withTheme, isNot(data));
      expect(
        SelectThemeData.lerp(data, withTheme, 1)!.skeletonViewTheme.color,
        _a,
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
          select: const SelectThemeData(
            skeletonViewTheme: SelectSkeletonViewTheme(color: _a),
          ),
        ),
      );
      expect(paintedColor(), _a);

      await tester.pumpWidget(
        _host(
          light,
          const SkeletonTile(height: 10, width: 10, color: _b),
          select: const SelectThemeData(
            skeletonViewTheme: SelectSkeletonViewTheme(color: _a),
          ),
        ),
      );
      expect(paintedColor(), _b);
    });
  });
}
