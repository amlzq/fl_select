// Verifies that the global SelectThemeData color tokens reach the widgets that
// document them, and that the Material defaults apply when they are unset.
import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _selected = Color(0xFF00AA00);
const _onBackground = Color(0xFFAA00AA);
const _onSelected = Color(0xFFFFEE00);

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

  group('onSelectedColor', () {
    const onSelected = SelectThemeData(onSelectedColor: _onSelected);

    testWidgets('colors selected filled grid tile text', (tester) async {
      await _pump(
        tester,
        onSelected,
        const SelectGridTile(
          label: 'x',
          selected: true,
          variant: SelectGridTileVariant.filled,
        ),
      );
      expect(_textColor(tester, 'x'), _onSelected);
    });

    testWidgets('does not change outlined grid tile text', (tester) async {
      const tile = SelectGridTile(
        label: 'x',
        selected: true,
        variant: SelectGridTileVariant.outlined,
      );
      await _pump(tester, null, tile);
      final baseline = _textColor(tester, 'x');
      await _pump(tester, onSelected, tile);
      expect(_textColor(tester, 'x'), baseline);
      expect(baseline, isNot(_onSelected));
    });

    test('filled chip label uses it over the brightness heuristic', () {
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.filled,
          Colors.black,
          onSelectedColor: _onSelected,
        ),
        _onSelected,
      );
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.filled,
          Colors.black,
        ),
        Colors.white,
      );
    });

    test('outlined chip label stays the selected chip color', () {
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.outlined,
          Colors.black,
          onSelectedColor: _onSelected,
        ),
        Colors.black,
      );
    });
  });

  group('SelectGridTile', () {
    testWidgets('outlined selected text uses the global selectedColor', (
      tester,
    ) async {
      await _pump(
        tester,
        data,
        const SelectGridTile(
          label: 'x',
          selected: true,
          variant: SelectGridTileVariant.outlined,
        ),
      );
      expect(_textColor(tester, 'x'), _selected);
    });

    testWidgets('applies the theme labelStyle but keeps the state color', (
      tester,
    ) async {
      await _pump(
        tester,
        data.copyWith(
          gridTileTheme: const SelectGridTileTheme(
            labelStyle: TextStyle(fontSize: 21, color: Colors.red),
          ),
        ),
        const SelectGridTile(label: 'x'),
      );
      final style = tester.widget<Text>(find.text('x')).style!;
      expect(style.fontSize, 21);
      expect(style.color, _onBackground);
    });

    testWidgets('renders sublabel, leading and trailing when given', (
      tester,
    ) async {
      await _pump(
        tester,
        null,
        const SelectGridTile(
          label: 'x',
          sublabel: 'sub',
          leading: Icon(Icons.add),
          trailing: Icon(Icons.remove),
        ),
      );
      expect(find.text('sub'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });
  });
}
