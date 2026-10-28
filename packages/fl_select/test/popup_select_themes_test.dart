import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('PopupSelectBarTheme', () {
    const theme = PopupSelectBarTheme(
      height: 40,
      backgroundColor: Color(0xFF111111),
      labelColor: Color(0xFF222222),
      labelStyle: TextStyle(fontSize: 10),
      unselectedLabelColor: Color(0xFF333333),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      overlayStyle: SelectOverlayStyle(maxWidth: 100),
      selectTheme: SelectThemeData(),
    );

    test('copyWith keeps and replaces', () {
      expect(theme.copyWith(), theme);
      final c = theme.copyWith(
        height: 50,
        backgroundColor: const Color(0xFF000001),
        labelColor: const Color(0xFF000002),
        labelStyle: const TextStyle(fontSize: 1),
        unselectedLabelColor: const Color(0xFF000003),
        unselectedLabelStyle: const TextStyle(fontSize: 2),
        indicator: const SizedBox(),
        unselectedIndicator: const SizedBox(),
        overlayStyle: const SelectOverlayStyle(maxWidth: 1),
        selectTheme: const SelectThemeData(),
      );
      expect(c.height, 50);
      expect(c.indicator, isNotNull);
      expect(c.unselectedIndicator, isNotNull);
      expect(c, isNot(theme));
    });

    test('equality and hashCode', () {
      expect(theme == theme.copyWith(), isTrue);
      expect(theme.hashCode, theme.copyWith().hashCode);
      expect(theme.copyWith(height: 1) == theme, isFalse);
      expect(
        theme.copyWith(backgroundColor: const Color(0xFF000000)) == theme,
        isFalse,
      );
      expect(
        theme.copyWith(labelColor: const Color(0xFF000000)) == theme,
        isFalse,
      );
      // ignore: unrelated_type_equality_checks
      expect(theme == Object(), isFalse);
    });

    test('lerp', () {
      expect(theme.lerp(null, .5), same(theme));
      const other = PopupSelectBarTheme(
        height: 60,
        backgroundColor: Color(0xFF999999),
        labelColor: Color(0xFF888888),
        labelStyle: TextStyle(fontSize: 20),
        unselectedLabelColor: Color(0xFF777777),
        unselectedLabelStyle: TextStyle(fontSize: 22),
      );
      final mid = theme.lerp(other, .5) as PopupSelectBarTheme;
      expect(mid.height, 50);
      expect(mid.labelStyle!.fontSize, 15);
      expect(mid.backgroundColor, isNotNull);
      expect(mid.unselectedLabelStyle!.fontSize, 17);

      const heightOnly = PopupSelectBarTheme(height: 10);
      const empty = PopupSelectBarTheme();
      expect((heightOnly.lerp(empty, .2) as PopupSelectBarTheme).height, 10);
      expect(
        (heightOnly.lerp(empty, .8) as PopupSelectBarTheme).height,
        isNull,
      );
    });

    testWidgets('maybeOf', (tester) async {
      PopupSelectBarTheme? found;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [PopupSelectBarTheme(height: 7)]),
          home: Builder(
            builder: (context) {
              found = PopupSelectBarTheme.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found?.height, 7);
    });
  });

  group('PopupSelectButtonTheme', () {
    const theme = PopupSelectButtonTheme(
      backgroundColor: Color(0xFF111111),
      foregroundColor: Color(0xFF222222),
      overlayColor: Color(0xFF333333),
      shadowColor: Color(0xFF444444),
      surfaceTintColor: Color(0xFF555555),
      side: BorderSide(width: 2),
      shape: RoundedRectangleBorder(),
      textStyle: TextStyle(fontSize: 10),
      iconColor: Color(0xFF666666),
      padding: EdgeInsets.all(4),
      elevation: 2,
      overlayStyle: SelectOverlayStyle(maxWidth: 100),
      selectTheme: SelectThemeData(),
    );

    test('copyWith keeps and replaces every field', () {
      expect(theme.copyWith(), theme);
      final c = theme.copyWith(
        backgroundColor: const Color(0xFF000001),
        foregroundColor: const Color(0xFF000002),
        overlayColor: const Color(0xFF000003),
        shadowColor: const Color(0xFF000004),
        surfaceTintColor: const Color(0xFF000005),
        side: const BorderSide(width: 5),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 1),
        iconColor: const Color(0xFF000006),
        padding: const EdgeInsets.all(9),
        elevation: 9,
        overlayStyle: const SelectOverlayStyle(maxWidth: 1),
        selectTheme: const SelectThemeData(),
      );
      expect(c.elevation, 9);
      expect(c.shape, const StadiumBorder());
      expect(c.side!.width, 5);
      expect(c, isNot(theme));
    });

    test('equality compares every field', () {
      expect(theme.hashCode, theme.copyWith().hashCode);
      final variants = <PopupSelectButtonTheme>[
        theme.copyWith(backgroundColor: const Color(0xFF000001)),
        theme.copyWith(foregroundColor: const Color(0xFF000001)),
        theme.copyWith(overlayColor: const Color(0xFF000001)),
        theme.copyWith(shadowColor: const Color(0xFF000001)),
        theme.copyWith(surfaceTintColor: const Color(0xFF000001)),
        theme.copyWith(side: const BorderSide(width: 7)),
        theme.copyWith(shape: const StadiumBorder()),
        theme.copyWith(textStyle: const TextStyle(fontSize: 1)),
        theme.copyWith(iconColor: const Color(0xFF000001)),
        theme.copyWith(padding: const EdgeInsets.all(1)),
        theme.copyWith(elevation: 1),
        theme.copyWith(overlayStyle: const SelectOverlayStyle(maxWidth: 1)),
      ];
      for (final v in variants) {
        expect(v == theme, isFalse);
      }
      // ignore: unrelated_type_equality_checks
      expect(theme == Object(), isFalse);
    });

    test('lerp', () {
      expect(theme.lerp(null, .5), same(theme));
      const other = PopupSelectButtonTheme(
        backgroundColor: Color(0xFF999999),
        side: BorderSide(width: 4),
        shape: RoundedRectangleBorder(),
        textStyle: TextStyle(fontSize: 20),
        padding: EdgeInsets.all(8),
        elevation: 6,
      );
      final mid = theme.lerp(other, .5) as PopupSelectButtonTheme;
      expect(mid.side!.width, 3);
      expect(mid.elevation, 4);
      expect(mid.padding, const EdgeInsets.all(6));
      expect(mid.textStyle!.fontSize, 15);

      const a = PopupSelectButtonTheme(
        side: BorderSide(width: 1),
        elevation: 1,
      );
      const b = PopupSelectButtonTheme();
      expect((a.lerp(b, .2) as PopupSelectButtonTheme).side!.width, 1);
      expect((a.lerp(b, .8) as PopupSelectButtonTheme).side, isNull);
      expect((a.lerp(b, .2) as PopupSelectButtonTheme).elevation, 1);
      expect((a.lerp(b, .8) as PopupSelectButtonTheme).elevation, isNull);
    });

    testWidgets('maybeOf', (tester) async {
      PopupSelectButtonTheme? found;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [PopupSelectButtonTheme(elevation: 3)],
          ),
          home: Builder(
            builder: (context) {
              found = PopupSelectButtonTheme.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found?.elevation, 3);
    });
  });
}
