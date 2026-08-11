import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectLayout base', () {
    test('is the common supertype of all concrete layouts', () {
      expect(const SelectListLayout(), isA<SelectLayout>());
      expect(const SelectGridLayout(crossAxisCount: 2), isA<SelectLayout>());
      expect(const SelectChipLayout(), isA<SelectLayout>());
      expect(const SelectRangeLayout(), isA<SelectLayout>());
    });
  });

  group('SelectListLayout', () {
    test('== and hashCode: equal layouts are identical', () {
      const a = SelectListLayout();
      const b = SelectListLayout();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different toText makes layouts unequal', () {
      const a = SelectListLayout();
      const b = SelectListLayout(toText: 'and');
      expect(a, isNot(equals(b)));
    });

    test('toText defaults to "-"', () {
      expect(const SelectListLayout().toText, '-');
    });
  });

  group('SelectGridLayout', () {
    test('== and hashCode: equal layouts are identical', () {
      const a = SelectGridLayout(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
      );
      const b = SelectGridLayout(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different crossAxisCount makes layouts unequal', () {
      const a = SelectGridLayout(crossAxisCount: 2);
      const b = SelectGridLayout(crossAxisCount: 3);
      expect(a, isNot(equals(b)));
    });

    test('== and hashCode: different spacing makes layouts unequal', () {
      const a = SelectGridLayout(crossAxisCount: 2);
      const b = SelectGridLayout(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
      );
      expect(a, isNot(equals(b)));
    });

    test('defaults are applied', () {
      const layout = SelectGridLayout(crossAxisCount: 2);
      expect(layout.crossAxisCount, 2);
      expect(layout.mainAxisSpacing, 0.0);
      expect(layout.crossAxisSpacing, 0.0);
      expect(layout.childAspectRatio, 1.0);
      expect(layout.toText, '-');
    });
  });

  group('SelectChipLayout', () {
    test('== and hashCode: all instances are equal', () {
      const a = SelectChipLayout();
      const b = SelectChipLayout();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different spacing makes layouts unequal', () {
      const a = SelectChipLayout(spacing: 8, runSpacing: 12);
      const b = SelectChipLayout(spacing: 12, runSpacing: 12);
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('SelectRangeLayout', () {
    test('== and hashCode: equal layouts are identical', () {
      const a = SelectRangeLayout();
      const b = SelectRangeLayout();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different toText makes layouts unequal', () {
      const a = SelectRangeLayout();
      const b = SelectRangeLayout(toText: 'and');
      expect(a, isNot(equals(b)));
    });

    test('toText defaults to "-"', () {
      expect(const SelectRangeLayout().toText, '-');
    });
  });
}
