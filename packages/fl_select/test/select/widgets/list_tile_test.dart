import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/list_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _radioFill = Color(0xFF112233);
const _checkboxFill = Color(0xFF445566);

const _radioTheme = RadioThemeData(
  fillColor: WidgetStatePropertyAll(_radioFill),
);
const _checkboxTheme = CheckboxThemeData(
  fillColor: WidgetStatePropertyAll(_checkboxFill),
);

void main() {
  group('SelectThemeData radio/checkbox defaults', () {
    test('are unset until resolved', () {
      const data = SelectThemeData();

      expect(data.radioTheme, isNull);
      expect(data.checkboxTheme, isNull);
    });

    testWidgets('resolve to the Material ThemeData values', (tester) async {
      late BuildContext seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            radioTheme: _radioTheme,
            checkboxTheme: _checkboxTheme,
          ),
          home: Builder(
            builder: (context) {
              seen = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(SelectTheme.radioThemeOf(seen), _radioTheme);
      expect(SelectTheme.checkboxThemeOf(seen), _checkboxTheme);
    });

    testWidgets('explicit overrides win over the Material ThemeData values', (
      tester,
    ) async {
      const overrideRadio = RadioThemeData(splashRadius: 12);
      const overrideCheckbox = CheckboxThemeData(splashRadius: 16);
      late BuildContext seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            radioTheme: _radioTheme,
            checkboxTheme: _checkboxTheme,
          ),
          home: SelectTheme(
            data: const SelectThemeData(
              radioTheme: overrideRadio,
              checkboxTheme: overrideCheckbox,
            ),
            child: Builder(
              builder: (context) {
                seen = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(SelectTheme.radioThemeOf(seen), overrideRadio);
      expect(SelectTheme.checkboxThemeOf(seen), overrideCheckbox);
    });
  });

  group('SelectThemeData radioTheme', () {
    testWidgets('is applied to the default radio toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(radioTheme: _radioTheme),
            child: const Scaffold(
              body: SelectRadioListTile(label: 'A', selected: true),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Radio<int>));
      expect(RadioTheme.of(context), _radioTheme);
    });
  });

  group('SelectThemeData checkboxTheme', () {
    testWidgets('is applied to the default checkbox toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(checkboxTheme: _checkboxTheme),
            child: const Scaffold(
              body: SelectCheckboxListTile(label: 'A', checked: true),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Checkbox));
      expect(CheckboxTheme.of(context), _checkboxTheme);
    });
  });
}
