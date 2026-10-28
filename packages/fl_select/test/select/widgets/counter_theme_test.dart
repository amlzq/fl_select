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

    test('SelectThemeData carries it', () {
      const data = SelectThemeData();
      expect(data.counterTheme, const SelectCounterTheme());
      const withTheme = SelectThemeData(
        counterTheme: SelectCounterTheme(valueColor: _a),
      );
      expect(withTheme, isNot(data));
      expect(withTheme.copyWith().counterTheme.valueColor, _a);
      expect(
        SelectThemeData.lerp(data, withTheme, 1)!.counterTheme.valueColor,
        _a,
      );
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
          select: const SelectThemeData(
            counterTheme: SelectCounterTheme(valueColor: _a),
          ),
        ),
      );
      expect(valueColor(), _a);
    });
  });
}
