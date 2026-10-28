// Verifies that the global SelectThemeData color tokens reach the widgets that
// document them, and that the Material defaults apply when they are unset.
import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _selected = Color(0xFF00AA00);
const _onBackground = Color(0xFFAA00AA);

Future<void> _pump(
  WidgetTester tester,
  SelectThemeData? data,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectTheme(data: data ?? const SelectThemeData(), child: child),
      ),
    ),
  );
}

Color? _textColor(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  final style = DefaultTextStyle.of(tester.element(find.text(text))).style
      .merge(widget.style);
  return style.color;
}

void main() {
  const data = SelectThemeData(
    selectedColor: _selected,
    onBackgroundColor: _onBackground,
  );

  group('onBackgroundColor', () {
    testWidgets('colors unselected list tile text', (tester) async {
      await _pump(tester, data, const SelectListTile(label: 'x'));
      expect(_textColor(tester, 'x'), _onBackground);
    });

    testWidgets('colors unselected grid tile text', (tester) async {
      await _pump(tester, data, const SelectGridTile(label: 'x'));
      expect(_textColor(tester, 'x'), _onBackground);
    });

    testWidgets('falls back to onSurfaceVariant when unset', (tester) async {
      await _pump(tester, null, const SelectListTile(label: 'x'));
      final scheme = Theme.of(tester.element(find.text('x'))).colorScheme;
      expect(_textColor(tester, 'x'), scheme.onSurfaceVariant);
    });

    testWidgets('component theme still wins', (tester) async {
      await _pump(
        tester,
        data.copyWith(
          listTileTheme: const SelectListTileTheme(textColor: Colors.red),
        ),
        const SelectListTile(label: 'x'),
      );
      expect(_textColor(tester, 'x'), Colors.red);
    });

    testWidgets('colors the default chip label style', (tester) async {
      late TextStyle? style;
      await _pump(
        tester,
        data,
        Builder(
          builder: (context) {
            style = SelectChipDefaults(context).labelStyle;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(style?.color, _onBackground);
    });
  });

  group('selectedColor', () {
    testWidgets('colors selected list tile text', (tester) async {
      await _pump(
        tester,
        data,
        const SelectListTile(label: 'x', selected: true),
      );
      expect(_textColor(tester, 'x'), _selected);
    });

    testWidgets('falls back to primary when unset', (tester) async {
      await _pump(
        tester,
        null,
        const SelectListTile(label: 'x', selected: true),
      );
      final scheme = Theme.of(tester.element(find.text('x'))).colorScheme;
      expect(_textColor(tester, 'x'), scheme.primary);
    });
  });
}
