import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('selected label color', () {
    const custom = Color(0xFF12AB34);
    const onSelected = Color(0xFFFFEE00);
    final entry = SelectTextEntry<dynamic>(id: 'a', name: 'A');

    Widget wrap({TextStyle? style, SelectThemeData? theme}) {
      return MaterialApp(
        home: Scaffold(
          body: SelectTheme(
            data: theme ?? const SelectThemeData(),
            child: SelectWrapView(
              entries: [entry],
              selectedEntries: {entry},
              selectedLabelStyle: style,
              variant: SelectChipVariant.filled,
              onChanged: (_, _) {},
            ),
          ),
        ),
      );
    }

    TextStyle? labelStyle(WidgetTester tester) =>
        tester.widget<Text>(find.text('A')).style;

    testWidgets('explicit selectedLabelStyle color wins', (tester) async {
      await tester.pumpWidget(
        wrap(
          style: const TextStyle(color: custom),
          theme: const SelectThemeData(onSelectedColor: onSelected),
        ),
      );
      expect(labelStyle(tester)?.color, custom);
    });

    testWidgets('theme selectedLabelStyle color wins', (tester) async {
      await tester.pumpWidget(
        wrap(
          theme: const SelectThemeData(
            onSelectedColor: onSelected,
            wrapViewTheme: SelectWrapViewTheme(
              selectedLabelStyle: TextStyle(color: custom),
            ),
          ),
        ),
      );
      expect(labelStyle(tester)?.color, custom);
    });

    testWidgets('a style without color falls back to onSelectedColor', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          style: const TextStyle(fontSize: 20),
          theme: const SelectThemeData(onSelectedColor: onSelected),
        ),
      );
      expect(labelStyle(tester)?.color, onSelected);
      expect(labelStyle(tester)?.fontSize, 20);
    });

    testWidgets('without any override the color is derived', (tester) async {
      await tester.pumpWidget(wrap());
      expect(labelStyle(tester)?.color, isIn([Colors.white, Colors.black]));
    });
  });
}
