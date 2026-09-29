import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _e1 = Color(0xFF222222);
const _e2 = Color(0xFF444444);

void main() {
  group('SelectCascadingViewTheme', () {
    test('is value-equal by color content', () {
      expect(
        const SelectCascadingViewTheme(endBackgroundColor: _e1),
        const SelectCascadingViewTheme(endBackgroundColor: _e1),
      );
      expect(
        const SelectCascadingViewTheme(endBackgroundColor: _e1),
        isNot(const SelectCascadingViewTheme(endBackgroundColor: _e2)),
      );
      expect(
        const SelectCascadingViewTheme(endBackgroundColor: _e1).hashCode,
        const SelectCascadingViewTheme(endBackgroundColor: _e1).hashCode,
      );
    });

    test('copyWith replaces only the provided fields', () {
      const theme = SelectCascadingViewTheme(endBackgroundColor: _e1);

      expect(theme.copyWith().endBackgroundColor, _e1);
      expect(theme.copyWith(endBackgroundColor: _e2).endBackgroundColor, _e2);
      expect(
        const SelectCascadingViewTheme().copyWith().endBackgroundColor,
        null,
      );
    });

    test('merge keeps the base when other is null and overrides otherwise', () {
      const base = SelectCascadingViewTheme(endBackgroundColor: _e1);
      const other = SelectCascadingViewTheme(endBackgroundColor: _e2);

      expect(base.merge(null), base);
      expect(base.merge(other), other);
      expect(base.merge(const SelectCascadingViewTheme()), base);
      expect(const SelectCascadingViewTheme().merge(base), base);
    });

    test('lerp interpolates the end', () {
      final lerped = SelectCascadingViewTheme.lerp(
        const SelectCascadingViewTheme(endBackgroundColor: _e1),
        const SelectCascadingViewTheme(endBackgroundColor: _e2),
        0.5,
      );

      expect(lerped.endBackgroundColor, Color.lerp(_e1, _e2, 0.5));
    });

    test('lerp returns the same instance when both sides are identical', () {
      const theme = SelectCascadingViewTheme(endBackgroundColor: _e1);

      expect(
        identical(SelectCascadingViewTheme.lerp(theme, theme, 0.5), theme),
        isTrue,
      );
    });

    test('lerp keeps a resolved end at the boundary', () {
      expect(
        SelectCascadingViewTheme.lerp(
          const SelectCascadingViewTheme(endBackgroundColor: _e1),
          const SelectCascadingViewTheme(),
          0,
        ).endBackgroundColor,
        _e1,
      );
      expect(
        SelectCascadingViewTheme.lerp(
          const SelectCascadingViewTheme(),
          const SelectCascadingViewTheme(endBackgroundColor: _e2),
          1,
        ).endBackgroundColor,
        _e2,
      );
    });

    testWidgets('of() reads the ambient SelectTheme', (tester) async {
      late SelectCascadingViewTheme seen;
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(ThemeData.light()).copyWith(
              cascadingViewTheme: const SelectCascadingViewTheme(
                endBackgroundColor: _e1,
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

      expect(seen.endBackgroundColor, _e1);
    });
  });

  group('SelectThemeData.cascadingViewTheme', () {
    test('defaults to an empty theme', () {
      final data = SelectThemeData(ThemeData.light());

      expect(data.cascadingViewTheme, const SelectCascadingViewTheme());
      expect(data.cascadingViewTheme.endBackgroundColor, null);
    });

    test('participates in equality and interpolation', () {
      final withColor = SelectThemeData(
        ThemeData.light(),
        cascadingViewTheme: const SelectCascadingViewTheme(
          endBackgroundColor: _e1,
        ),
      );

      expect(withColor, isNot(SelectThemeData(ThemeData.light())));
      expect(
        SelectThemeData.lerp(
          withColor,
          SelectThemeData(ThemeData.light()),
          0,
        )!.cascadingViewTheme.endBackgroundColor,
        _e1,
      );
    });
  });
}
