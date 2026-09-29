import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _themeSideBarColor = Color(0xFF102030);
const _themeEndColor = Color(0xFF506070);
const _legacyCategoryColor = Color(0xFF112233);
const _legacyTerminalColor = Color(0xFF445566);

/// The ambient defaults the ramp falls back to when nothing overrides them.
final _defaultStartColor = SelectThemeData(ThemeData.light()).backgroundColor;
final _defaultEndColor = SelectThemeData(
  ThemeData.light(),
).backgroundColorHighest;

/// `Region` -> `East` -> `Shanghai`/`Hangzhou` spans three levels: the sidebar
/// (level 0), the children column (level 1) and the grandchildren column
/// (level 2). The background ramp is therefore three steps long, and the level 1
/// column takes its midpoint.
Set<SelectEntry> _entries() => {
  SelectCategoryEntry<dynamic>(
    id: 'region',
    name: 'Region',
    children: {
      SelectTextEntry<dynamic>(
        id: 'east',
        name: 'East',
        children: {
          SelectTextEntry<dynamic>(id: 'sh', name: 'Shanghai'),
          SelectTextEntry<dynamic>(id: 'hz', name: 'Hangzhou'),
        },
      ),
      SelectTextEntry<dynamic>(id: 'west', name: 'West'),
    },
  ),
};

/// Builds a [CascadingSelect] body so we can assert how the sidebar and the
/// cascade columns share one background ramp.
Widget _harness({
  Color? sideBarColor,
  Color? endColor,
  Color? legacyCategoryColor,
  Color? legacyTerminalColor,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: CascadingSelectDelegate(
          entriesLoader: () async => _entries(),
          sideBarTheme: sideBarColor == null
              ? null
              : SelectSideBarTheme(backgroundColor: sideBarColor),
          cascadingViewTheme: endColor == null
              ? null
              : SelectCascadingViewTheme(endBackgroundColor: endColor),
          // ignore: deprecated_member_use_from_same_package
          categoryBackgroundColor: legacyCategoryColor,
          // ignore: deprecated_member_use_from_same_package
          terminalBackgroundColor: legacyTerminalColor,
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

/// The background color the category sidebar paints.
Color _paintedSideBarColor(WidgetTester tester) {
  return tester
      .widget<Container>(
        find
            .descendant(
              of: find.byType(SelectSideBar),
              matching: find.byType(Container),
            )
            .first,
      )
      .color!;
}

/// The background colors the cascade columns paint.
List<Color> _columnColors(WidgetTester tester) {
  return tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(CascadingView),
          matching: find.byType(ColoredBox),
        ),
      )
      .map((box) => box.color)
      .toList();
}

void main() {
  group('CascadingSelect background ramp', () {
    testWidgets('the sidebar and the cascade share one ramp', (tester) async {
      await tester.pumpWidget(
        _harness(sideBarColor: _themeSideBarColor, endColor: _themeEndColor),
      );
      await tester.pumpAndSettle();

      expect(_paintedSideBarColor(tester), _themeSideBarColor);
      // Level 0 is the surface the sidebar paints, so the view starts ramping
      // from it and only paints level 1 onwards.
      expect(
        _columnColors(tester),
        contains(Color.lerp(_themeSideBarColor, _themeEndColor, 0.5)),
      );
      expect(_columnColors(tester), isNot(contains(_themeSideBarColor)));
    });

    testWidgets('the sidebar theme wins over the deprecated category color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          sideBarColor: _themeSideBarColor,
          legacyCategoryColor: _legacyCategoryColor,
        ),
      );
      await tester.pumpAndSettle();

      expect(_paintedSideBarColor(tester), _themeSideBarColor);
      expect(
        _columnColors(tester),
        contains(Color.lerp(_themeSideBarColor, _defaultEndColor, 0.5)),
      );
    });

    testWidgets('the cascading theme end wins over the deprecated terminal '
        'color', (tester) async {
      await tester.pumpWidget(
        _harness(
          endColor: _themeEndColor,
          legacyTerminalColor: _legacyTerminalColor,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(_columnColors(tester), contains(_themeEndColor));
      expect(_columnColors(tester), isNot(contains(_legacyTerminalColor)));
    });

    group('deprecated delegate colors', () {
      testWidgets('categoryBackgroundColor still anchors the ramp', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(legacyCategoryColor: _legacyCategoryColor),
        );
        await tester.pumpAndSettle();

        // The sidebar paints it, and the columns ramp up from it.
        expect(_paintedSideBarColor(tester), _legacyCategoryColor);
        expect(
          _columnColors(tester),
          contains(Color.lerp(_legacyCategoryColor, _defaultEndColor, 0.5)),
        );
      });

      testWidgets('terminalBackgroundColor still ends the ramp', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(legacyTerminalColor: _legacyTerminalColor),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('East'));
        await tester.pumpAndSettle();

        // The deepest column (level 2) paints the end of the ramp.
        expect(_columnColors(tester), contains(_legacyTerminalColor));
      });

      testWidgets(
        'the ramp still starts from the panel background by default',
        (tester) async {
          await tester.pumpWidget(_harness());
          await tester.pumpAndSettle();

          expect(_paintedSideBarColor(tester), _defaultStartColor);
          expect(
            _columnColors(tester),
            contains(Color.lerp(_defaultStartColor, _defaultEndColor, 0.5)),
          );
        },
      );
    });
  });
}
