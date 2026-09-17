import 'package:fl_select/fl_select.dart'
    show SelectChipVariant, SelectTheme, SelectThemeData;
import 'package:fl_select/src/select/widgets/widgets.dart'
    show SelectChipBarDefaults, SelectChipDefaults, SelectWrapViewDefaults;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves the defaults of both chip views from the same inherited theme, the
/// way each view resolves them while building.
Future<(SelectChipBarDefaults, SelectWrapViewDefaults)> _defaults(
  WidgetTester tester, {
  required Brightness brightness,
  SelectChipVariant? variant,
}) async {
  late SelectChipBarDefaults bar;
  late SelectWrapViewDefaults wrap;
  final theme = ThemeData(brightness: brightness);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: SelectTheme(
        data: SelectThemeData(theme),
        child: Builder(
          builder: (context) {
            bar = SelectChipBarDefaults(context, variant);
            wrap = SelectWrapViewDefaults(context, variant);
            return const SizedBox();
          },
        ),
      ),
    ),
  );

  return (bar, wrap);
}

void main() {
  group('SelectChipDefaults', () {
    // SelectChip is the item of both chip views, so neither may drift apart on
    // the item's default visuals.
    testWidgets('both chip views resolve identical chip visuals', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        for (final variant in <SelectChipVariant?>[
          null,
          SelectChipVariant.filled,
          SelectChipVariant.outlined,
        ]) {
          final (bar, wrap) = await _defaults(
            tester,
            brightness: brightness,
            variant: variant,
          );
          final where = '$brightness / $variant';

          expect(wrap.chipColor, bar.chipColor, reason: where);
          expect(wrap.selectedChipColor, bar.selectedChipColor, reason: where);
          expect(wrap.labelStyle, bar.labelStyle, reason: where);
          expect(
            wrap.selectedLabelStyle,
            bar.selectedLabelStyle,
            reason: where,
          );
        }
      }
    });

    // The views own their container defaults independently, so they are
    // asserted per view instead of against each other.
    testWidgets(
      'both chip views default to a transparent, unpadded container',
      (tester) async {
        final (bar, wrap) = await _defaults(
          tester,
          brightness: Brightness.light,
        );

        expect(bar.backgroundColor, Colors.transparent);
        expect(wrap.backgroundColor, Colors.transparent);
        expect(bar.padding, EdgeInsets.zero);
        expect(wrap.padding, EdgeInsets.zero);
      },
    );

    test('selectedTextColor contrasts with a filled chip color', () {
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.filled,
          Colors.black,
        ),
        Colors.white,
      );
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.filled,
          Colors.white,
        ),
        Colors.black,
      );
    });

    test('selectedTextColor reuses the color on an outlined chip', () {
      expect(
        SelectChipDefaults.selectedTextColor(
          SelectChipVariant.outlined,
          Colors.teal,
        ),
        Colors.teal,
      );
    });
  });
}
