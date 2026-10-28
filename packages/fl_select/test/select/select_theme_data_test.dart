import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);

void main() {
  group('SelectThemeData defaults', () {
    test('leaves every color and control theme unset', () {
      const data = SelectThemeData();

      expect(data.selectedColor, isNull);
      expect(data.onSelectedColor, isNull);
      expect(data.backgroundColor, isNull);
      expect(data.onBackgroundColor, isNull);
      expect(data.radioTheme, isNull);
      expect(data.checkboxTheme, isNull);
    });

    test('starts every component theme empty', () {
      const data = SelectThemeData();

      expect(data.actionBarTheme, const SelectActionBarTheme());
      expect(data.tabBarTheme, const SelectTabBarTheme());
      expect(data.sideBarTheme, const SelectSideBarTheme());
      expect(data.gridTileTheme, const SelectGridTileTheme());
      expect(data.listTileTheme, const SelectListTileTheme());
      expect(data.fieldTileTheme, const SelectFieldTileTheme());
      expect(data.expansionTileTheme, const SelectExpansionTileTheme());
      expect(data.rangeSliderTheme, const SelectRangeSliderTheme());
      expect(data.chipBarTheme, const SelectChipBarTheme());
      expect(data.panelTheme, const SelectPanelTheme());
      expect(data.searchBarTheme, const SelectSearchBarTheme());
      expect(data.wrapViewTheme, const SelectWrapViewTheme());
      expect(data.cascadingViewTheme, const SelectCascadingViewTheme());
      expect(data.skeletonViewTheme, const SelectSkeletonViewTheme());
      expect(data.counterTheme, const SelectCounterTheme());
    });
  });

  group('SelectThemeData.copyWith', () {
    test('replaces only the provided fields', () {
      const data = SelectThemeData(
        selectedColor: _red,
        listTileTheme: SelectListTileTheme(textColor: _red),
      );
      final copy = data.copyWith(backgroundColor: _blue);

      expect(copy.selectedColor, _red);
      expect(copy.backgroundColor, _blue);
      expect(copy.listTileTheme.textColor, _red);
    });

    test('cannot clear a field back to unset', () {
      const data = SelectThemeData(selectedColor: _red);

      expect(data.copyWith().selectedColor, _red);
    });
  });

  group('SelectThemeData equality', () {
    test('ignores the deprecated Highest colors', () {
      const a = SelectThemeData(selectedColor: _red);
      const b = SelectThemeData(
        selectedColor: _red,
        backgroundColorHigh: _blue,
        backgroundColorHighest: _blue,
        onBackgroundColorHighest: _blue,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('is value-equal over every field', () {
      const a = SelectThemeData(
        selectedColor: _red,
        radioTheme: RadioThemeData(splashRadius: 4),
        counterTheme: SelectCounterTheme(valueColor: _red),
      );
      const b = SelectThemeData(
        selectedColor: _red,
        radioTheme: RadioThemeData(splashRadius: 4),
        counterTheme: SelectCounterTheme(valueColor: _red),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(onSelectedColor: _blue)));
      expect(a, isNot(a.copyWith(counterTheme: const SelectCounterTheme())));
      expect(a, isNot(a.copyWith(checkboxTheme: const CheckboxThemeData())));
    });
  });

  group('SelectThemeData.lerp', () {
    test('returns the same instance when both sides are identical', () {
      const data = SelectThemeData(selectedColor: _red);

      expect(identical(SelectThemeData.lerp(data, data, 0.5), data), isTrue);
    });

    test('interpolates the set colors', () {
      const a = SelectThemeData(selectedColor: _red, backgroundColor: _red);
      const b = SelectThemeData(selectedColor: _blue, backgroundColor: _blue);
      final mid = SelectThemeData.lerp(a, b, 0.5)!;

      expect(mid.selectedColor, Color.lerp(_red, _blue, 0.5));
      expect(mid.backgroundColor, Color.lerp(_red, _blue, 0.5));
    });

    test('keeps unset colors unset when neither side sets them', () {
      final mid = SelectThemeData.lerp(
        const SelectThemeData(),
        const SelectThemeData(),
        0.5,
      )!;
      final mixed = SelectThemeData.lerp(
        const SelectThemeData(),
        const SelectThemeData(selectedColor: _blue),
        1,
      )!;

      expect(mid.selectedColor, isNull);
      expect(mid.radioTheme, isNull);
      expect(mid.checkboxTheme, isNull);
      expect(mixed.selectedColor, _blue);
    });

    test('interpolates control and component themes', () {
      const a = SelectThemeData(
        radioTheme: RadioThemeData(splashRadius: 0),
        listTileTheme: SelectListTileTheme(textColor: _red),
      );
      const b = SelectThemeData(
        radioTheme: RadioThemeData(splashRadius: 10),
        listTileTheme: SelectListTileTheme(textColor: _blue),
      );
      final mid = SelectThemeData.lerp(a, b, 0.5)!;

      expect(mid.radioTheme!.splashRadius, 5);
      expect(mid.listTileTheme.textColor, Color.lerp(_red, _blue, 0.5));
    });
  });
}
