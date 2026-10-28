import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _ambientTile = Color(0xFFAA0000);
const _triggerText = Color(0xFF0000AA);

void main() {
  testWidgets(
    'overlay panel keeps ambient SelectTheme values the trigger theme leaves '
    'unset',
    (tester) async {
      await tester.pumpWidget(
        SelectTheme(
          data: const SelectThemeData(
            listTileTheme: SelectListTileTheme(tileColor: _ambientTile),
          ),
          child: MaterialApp(
            theme: ThemeData(
              extensions: const [
                PopupSelectButtonTheme(
                  selectTheme: SelectThemeData(
                    listTileTheme: SelectListTileTheme(textColor: _triggerText),
                  ),
                ),
              ],
            ),
            home: Scaffold(
              body: PopupSelectButton(
                label: 'Filter',
                selectDelegate: ListSelectDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>(id: 'a', name: 'A'),
                  },
                ),
                onApplied: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      final data = SelectTheme.of(tester.element(find.byType(SelectPanel)));
      expect(data.listTileTheme.textColor, _triggerText);
      expect(data.listTileTheme.tileColor, _ambientTile);
    },
  );
}
