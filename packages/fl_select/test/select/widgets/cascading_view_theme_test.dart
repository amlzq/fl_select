import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = [Color(0xFF111111), Color(0xFF222222)];
const _b = [Color(0xFF333333), Color(0xFF444444)];

void main() {
  group('SelectCascadingViewTheme', () {
    test('is value-equal by list content', () {
      expect(
        const SelectCascadingViewTheme(backgroundColors: _a),
        const SelectCascadingViewTheme(backgroundColors: _a),
      );
      expect(
        const SelectCascadingViewTheme(backgroundColors: _a),
        isNot(const SelectCascadingViewTheme(backgroundColors: _b)),
      );
      expect(
        const SelectCascadingViewTheme(backgroundColors: _a).hashCode,
        const SelectCascadingViewTheme(backgroundColors: _a).hashCode,
      );
    });

    test('copyWith replaces only the provided fields', () {
      const theme = SelectCascadingViewTheme(backgroundColors: _a);

      expect(theme.copyWith().backgroundColors, _a);
      expect(theme.copyWith(backgroundColors: _b).backgroundColors, _b);
      expect(
        const SelectCascadingViewTheme().copyWith().backgroundColors,
        null,
      );
    });

    test('merge keeps the base when other is null and overrides otherwise', () {
      const base = SelectCascadingViewTheme(backgroundColors: _a);

      expect(base.merge(null).backgroundColors, _a);
      expect(
        base
            .merge(const SelectCascadingViewTheme(backgroundColors: _b))
            .backgroundColors,
        _b,
      );
      expect(base.merge(const SelectCascadingViewTheme()).backgroundColors, _a);
      expect(
        const SelectCascadingViewTheme()
            .merge(const SelectCascadingViewTheme(backgroundColors: _b))
            .backgroundColors,
        _b,
      );
    });

    test('lerp interpolates element-wise for equally long palettes', () {
      final lerped = SelectCascadingViewTheme.lerp(
        const SelectCascadingViewTheme(backgroundColors: _a),
        const SelectCascadingViewTheme(backgroundColors: _b),
        0.5,
      );

      expect(lerped.backgroundColors, [
        Color.lerp(_a[0], _b[0], 0.5),
        Color.lerp(_a[1], _b[1], 0.5),
      ]);
    });

    test('lerp switches when only one side is set', () {
      expect(
        SelectCascadingViewTheme.lerp(
          const SelectCascadingViewTheme(backgroundColors: _a),
          const SelectCascadingViewTheme(),
          0.25,
        ).backgroundColors,
        _a,
      );
      expect(
        SelectCascadingViewTheme.lerp(
          const SelectCascadingViewTheme(),
          const SelectCascadingViewTheme(backgroundColors: _b),
          0.75,
        ).backgroundColors,
        _b,
      );
    });

    testWidgets('of() reads the ambient SelectTheme', (tester) async {
      late SelectCascadingViewTheme seen;
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(ThemeData.light()).copyWith(
              cascadingViewTheme: const SelectCascadingViewTheme(
                backgroundColors: _a,
              ),
            ),
            child: Builder(
              builder: (context) {
                seen = SelectCascadingViewTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(seen.backgroundColors, _a);
    });
  });

  group('SelectThemeData.cascadingViewTheme', () {
    test('defaults to an empty theme', () {
      final data = SelectThemeData(ThemeData.light());

      expect(data.cascadingViewTheme, const SelectCascadingViewTheme());
      expect(data.cascadingViewTheme.backgroundColors, null);
    });

    test('participates in equality and interpolation', () {
      final withPalette = SelectThemeData(
        ThemeData.light(),
        cascadingViewTheme: const SelectCascadingViewTheme(
          backgroundColors: _a,
        ),
      );

      expect(withPalette, isNot(SelectThemeData(ThemeData.light())));
      expect(
        SelectThemeData.lerp(
          withPalette,
          SelectThemeData(ThemeData.light()),
          0,
        )!.cascadingViewTheme.backgroundColors,
        _a,
      );
    });
  });
}
