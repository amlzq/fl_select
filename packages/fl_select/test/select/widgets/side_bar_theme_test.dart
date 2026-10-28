import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _a = Color(0xFF111111);

void main() {
  group('SelectSideBarTheme.resolveSelectedTileColor', () {
    testWidgets('prefers the theme token over the ColorScheme', (tester) async {
      late Color seen;
      final light = ThemeData.light();
      Widget build(SelectThemeData? select) {
        final body = Builder(
          builder: (context) {
            seen = SelectSideBarTheme.resolveSelectedTileColor(context);
            return const SizedBox.shrink();
          },
        );
        return MaterialApp(
          theme: light,
          home: select == null ? body : SelectTheme(data: select, child: body),
        );
      }

      await tester.pumpWidget(build(null));
      expect(seen, light.colorScheme.surfaceContainerLow);

      await tester.pumpWidget(
        build(
          const SelectThemeData(
            sideBarTheme: SelectSideBarTheme(selectedTileColor: _a),
          ),
        ),
      );
      expect(seen, _a);
    });
  });
}
