import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('SelectOverlayStyle', () {
    test('defaults', () {
      const style = SelectOverlayStyle();
      expect(style.maxHeightFactor, isNull);
      expect(style.minWidth, isNull);
      expect(style.maxWidth, isNull);
      expect(style.barrierColor, isNull);
      expect(style.barrierIntercept, isTrue);
    });

    test('copyWith replaces only the given fields', () {
      const base = SelectOverlayStyle(
        maxHeightFactor: .5,
        minWidth: 10,
        maxWidth: 20,
        barrierColor: Color(0xFF000000),
      );
      final copy = base.copyWith(maxWidth: 99, barrierIntercept: false);
      expect(copy.maxHeightFactor, .5);
      expect(copy.minWidth, 10);
      expect(copy.maxWidth, 99);
      expect(copy.barrierColor, const Color(0xFF000000));
      expect(copy.barrierIntercept, isFalse);
      expect(base.copyWith(), base);
    });

    test('equality and hashCode', () {
      const a = SelectOverlayStyle(maxHeightFactor: .5, minWidth: 1);
      const b = SelectOverlayStyle(maxHeightFactor: .5, minWidth: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a, isTrue);
      expect(a == const SelectOverlayStyle(maxHeightFactor: .6), isFalse);
      expect(a == const SelectOverlayStyle(minWidth: 2), isFalse);
      expect(a.copyWith(maxWidth: 5) == a, isFalse);
      expect(a.copyWith(barrierColor: const Color(0x01000000)) == a, isFalse);
      expect(a.copyWith(barrierIntercept: false) == a, isFalse);
      // ignore: unrelated_type_equality_checks
      expect(a == Object(), isFalse);
    });
  });
}
