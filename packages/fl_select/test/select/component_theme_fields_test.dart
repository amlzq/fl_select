// Guards every component theme against a field being added to the class but
// forgotten in `copyWith`, `merge`, `lerp`, `==` or `hashCode`.
//
// Each theme is described by two fully populated field maps (`a` and `b`, every
// field different). Constructors and `copyWith` are invoked through
// `Function.apply`, so a new field only needs one entry in `_values`.
import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _toggleA(BuildContext context, bool selected) => const SizedBox();
Widget _toggleB(BuildContext context, bool selected) => const Placeholder();

/// Two distinct values per field name: index 0 for `a`, index 1 for `b`.
final Map<String, List<Object>> _values = {
  // Colors.
  for (final name in const [
    'backgroundColor',
    'startBackgroundColor',
    'endBackgroundColor',
    'valueColor',
    'selectedValueColor',
    'chipColor',
    'selectedChipColor',
    'selectedColor',
    'textColor',
    'tileColor',
    'selectedTileColor',
    'activeTrackColor',
    'inactiveTrackColor',
    'thumbColor',
    'thumbFillColor',
    'fillColor',
    'enabledBorderColor',
    'focusedBorderColor',
    'iconColor',
    'indicatorColor',
    'color',
    'shadowColor',
    'surfaceTintColor',
  ])
    name: const <Object>[Color(0xFF112233), Color(0xFF445566)],
  // Text styles.
  for (final name in const [
    'labelStyle',
    'sublabelStyle',
    'selectedLabelStyle',
    'titleStyle',
    'endLabelStyle',
    'hintStyle',
    'textStyle',
  ])
    name: const <Object>[
      TextStyle(fontSize: 10, color: Color(0xFF010101)),
      TextStyle(fontSize: 20, color: Color(0xFF020202)),
    ],
  // Insets.
  for (final name in const [
    'padding',
    'contentPadding',
    'titlePadding',
    'childPadding',
    'indicatorPadding',
  ])
    name: const <Object>[EdgeInsets.all(2), EdgeInsets.all(6)],
  // Numbers.
  for (final name in const [
    'width',
    'trackHeight',
    'thumbRadius',
    'borderRadius',
    'borderWidth',
    'iconSize',
    'indicatorHeight',
    'elevation',
  ])
    name: const <Object>[3.0, 9.0],
  'resetFlex': const <Object>[1, 2],
  'applyFlex': const <Object>[3, 4],
  'filled': const <Object>[true, false],
  'animationDuration': const <Object>[
    Duration(milliseconds: 100),
    Duration(milliseconds: 200),
  ],
  'indicatorAnimationDuration': const <Object>[
    Duration(milliseconds: 300),
    Duration(milliseconds: 400),
  ],
  'expansionCurve': const <Object>[Curves.linear, Curves.easeIn],
  'collapseCurve': const <Object>[Curves.easeOut, Curves.bounceIn],
  'resetButtonStyle': <Object>[
    ButtonStyle(elevation: WidgetStateProperty.all(1)),
    ButtonStyle(elevation: WidgetStateProperty.all(2)),
  ],
  'applyButtonStyle': <Object>[
    ButtonStyle(elevation: WidgetStateProperty.all(3)),
    ButtonStyle(elevation: WidgetStateProperty.all(4)),
  ],
  'radioBuilder': <Object>[_toggleA, _toggleB],
  'checkboxBuilder': <Object>[_toggleB, _toggleA],
  'indicatorSize': const <Object>[
    SelectTabBarIndicatorSize.tab,
    SelectTabBarIndicatorSize.label,
  ],
  'shape': const <Object>[
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
  ],
  'clipBehavior': const <Object>[Clip.hardEdge, Clip.antiAlias],
};

class _Spec {
  _Spec(
    this.name,
    this.ctor,
    this.fields,
    this.lerp, {
    this.variants = const {},
    this.opaqueLerp = const {},
  });

  final String name;
  final Function ctor;
  final List<String> fields;
  final dynamic Function(dynamic a, dynamic b, double t) lerp;

  /// Per-theme values for fields whose type differs between themes.
  final Map<String, List<Object>> variants;

  /// Fields whose Flutter `lerp` returns a fresh, never-`==` object (e.g.
  /// [ButtonStyle]); they are left out of the lerp equality checks.
  final Set<String> opaqueLerp;

  Object value(String field, int i) => (variants[field] ?? _values[field])![i];

  Map<Symbol, Object> map(int i, {Map<String, int> pick = const {}}) => {
    for (final f in fields) Symbol(f): value(f, pick[f] ?? i),
  };

  dynamic build(Map<Symbol, Object> m) => Function.apply(ctor, [], m);
}

final _specs = <_Spec>[
  _Spec(
    'SelectActionBarTheme',
    SelectActionBarTheme.new,
    const [
      'backgroundColor',
      'padding',
      'resetFlex',
      'applyFlex',
      'resetButtonStyle',
      'applyButtonStyle',
    ],
    (a, b, t) => SelectActionBarTheme.lerp(a, b, t),
    opaqueLerp: const {'resetButtonStyle', 'applyButtonStyle'},
  ),
  _Spec('SelectCascadingViewTheme', SelectCascadingViewTheme.new, const [
    'startBackgroundColor',
    'endBackgroundColor',
  ], (a, b, t) => SelectCascadingViewTheme.lerp(a, b, t)),
  _Spec(
    'SelectChipBarTheme',
    SelectChipBarTheme.new,
    const [
      'backgroundColor',
      'padding',
      'variant',
      'chipColor',
      'selectedChipColor',
      'labelStyle',
      'selectedLabelStyle',
    ],
    (a, b, t) => SelectChipBarTheme.lerp(a, b, t),
    variants: const {
      'variant': [SelectChipVariant.filled, SelectChipVariant.outlined],
    },
  ),
  _Spec('SelectCounterTheme', SelectCounterTheme.new, const [
    'valueColor',
    'selectedValueColor',
  ], (a, b, t) => SelectCounterTheme.lerp(a, b, t)),
  _Spec('SelectExpansionTileTheme', SelectExpansionTileTheme.new, const [
    'titleStyle',
    'titlePadding',
    'selectedColor',
    'childPadding',
    'animationDuration',
    'expansionCurve',
    'collapseCurve',
  ], (a, b, t) => SelectExpansionTileTheme.lerp(a, b, t)),
  _Spec(
    'SelectFieldTileTheme',
    SelectFieldTileTheme.new,
    const [
      'selectedColor',
      'textColor',
      'labelStyle',
      'sublabelStyle',
      'variant',
      'tileColor',
      'selectedTileColor',
    ],
    (a, b, t) => SelectFieldTileTheme.lerp(a, b, t),
    variants: const {
      'variant': [
        SelectFieldTileVariant.filled,
        SelectFieldTileVariant.outlined,
      ],
    },
  ),
  _Spec(
    'SelectGridTileTheme',
    SelectGridTileTheme.new,
    const [
      'selectedColor',
      'textColor',
      'labelStyle',
      'sublabelStyle',
      'variant',
      'tileColor',
      'selectedTileColor',
    ],
    (a, b, t) => SelectGridTileTheme.lerp(a, b, t),
    variants: const {
      'variant': [SelectGridTileVariant.filled, SelectGridTileVariant.outlined],
    },
  ),
  _Spec('SelectListTileTheme', SelectListTileTheme.new, const [
    'selectedColor',
    'textColor',
    'tileColor',
    'selectedTileColor',
    'labelStyle',
    'sublabelStyle',
    'radioBuilder',
    'checkboxBuilder',
  ], (a, b, t) => SelectListTileTheme.lerp(a, b, t)),
  _Spec('SelectRangeSliderTheme', SelectRangeSliderTheme.new, const [
    'endLabelStyle',
    'activeTrackColor',
    'inactiveTrackColor',
    'thumbColor',
    'thumbFillColor',
    'selectedColor',
    'trackHeight',
    'thumbRadius',
  ], (a, b, t) => SelectRangeSliderTheme.lerp(a, b, t)),
  _Spec('SelectSearchBarTheme', SelectSearchBarTheme.new, const [
    'padding',
    'contentPadding',
    'borderRadius',
    'filled',
    'fillColor',
    'enabledBorderColor',
    'focusedBorderColor',
    'borderWidth',
    'hintStyle',
    'textStyle',
    'iconColor',
    'iconSize',
  ], (a, b, t) => SelectSearchBarTheme.lerp(a, b, t)),
  _Spec('SelectSideBarTheme', SelectSideBarTheme.new, const [
    'backgroundColor',
    'width',
    'padding',
    'selectedColor',
    'labelStyle',
    'selectedLabelStyle',
    'selectedTileColor',
    'indicatorColor',
    'indicatorHeight',
    'indicatorPadding',
    'indicatorAnimationDuration',
  ], (a, b, t) => SelectSideBarTheme.lerp(a, b, t)),
  _Spec('SelectSkeletonViewTheme', SelectSkeletonViewTheme.new, const [
    'color',
  ], (a, b, t) => SelectSkeletonViewTheme.lerp(a, b, t)),
  _Spec('SelectTabBarTheme', SelectTabBarTheme.new, const [
    'backgroundColor',
    'padding',
    'selectedColor',
    'labelStyle',
    'selectedLabelStyle',
    'indicatorColor',
    'indicatorHeight',
    'indicatorPadding',
    'indicatorSize',
    'indicatorAnimationDuration',
  ], (a, b, t) => SelectTabBarTheme.lerp(a, b, t)),
  _Spec(
    'SelectWrapViewTheme',
    SelectWrapViewTheme.new,
    const [
      'backgroundColor',
      'padding',
      'variant',
      'chipColor',
      'selectedChipColor',
      'labelStyle',
      'selectedLabelStyle',
    ],
    (a, b, t) => SelectWrapViewTheme.lerp(a, b, t),
    variants: const {
      'variant': [SelectChipVariant.filled, SelectChipVariant.outlined],
    },
  ),
  _Spec('SelectPanelTheme', SelectPanelTheme.new, const [
    'elevation',
    'shadowColor',
    'surfaceTintColor',
    'shape',
    'clipBehavior',
  ], (a, b, t) => SelectPanelTheme.lerp(a, b, t)),
];

void main() {
  for (final spec in _specs) {
    group('${spec.name} field coverage', () {
      late dynamic empty;
      late dynamic a;
      late dynamic b;

      setUp(() {
        empty = spec.build(const {});
        a = spec.build(spec.map(0));
        b = spec.build(spec.map(1));
      });

      test('fixtures cover every constructor field', () {
        // A field missing from the spec would silently escape the checks
        // below; every `a` field must be non-null and differ from `b`.
        expect(a, isNot(empty));
        expect(a, isNot(b));
        for (final f in spec.fields) {
          expect(
            spec.value(f, 0),
            isNot(spec.value(f, 1)),
            reason: '$f needs two distinct sample values',
          );
        }
      });

      test('copyWith applies every field and keeps the rest', () {
        expect(Function.apply(a.copyWith as Function, [], spec.map(1)), b);
        expect(a.copyWith(), a);
        for (final f in spec.fields) {
          final one = Function.apply(a.copyWith as Function, [], {
            Symbol(f): spec.value(f, 1),
          });
          expect(
            one,
            spec.build(spec.map(0, pick: {f: 1})),
            reason: 'copyWith dropped or leaked "$f"',
          );
        }
      });

      test('merge overrides with every set field of the argument', () {
        expect(a.merge(b), b);
        expect(a.merge(empty), a);
        expect(a.merge(null), a);
        expect(empty.merge(a), a);
        for (final f in spec.fields) {
          final onlyF = spec.build({Symbol(f): spec.value(f, 1)});
          expect(
            a.merge(onlyF),
            spec.build(spec.map(0, pick: {f: 1})),
            reason: 'merge ignored "$f"',
          );
        }
      });

      test('== and hashCode see every field', () {
        expect(spec.build(spec.map(0)), a);
        expect(spec.build(spec.map(0)).hashCode, a.hashCode);
        for (final f in spec.fields) {
          final changed = spec.build(spec.map(0, pick: {f: 1}));
          expect(changed, isNot(a), reason: '== ignores "$f"');
          // Without the field in the hash, equal-hash collisions would be
          // legal, so only the == direction is asserted for it.
          final onlyF = spec.build({Symbol(f): spec.value(f, 0)});
          expect(onlyF, isNot(empty), reason: '== ignores "$f" vs unset');
        }
      });

      test('lerp reaches both ends and handles unset sides', () {
        final lerped = spec.fields.where((f) => !spec.opaqueLerp.contains(f));
        Map<Symbol, Object> only(int i) => {
          for (final f in lerped) Symbol(f): spec.value(f, i),
        };
        final la = spec.build(only(0));
        final lb = spec.build(only(1));
        for (final f in lerped) {
          final fa = spec.build({Symbol(f): spec.value(f, 0)});
          final fb = spec.build({Symbol(f): spec.value(f, 1)});
          expect(spec.lerp(fa, fb, 0), fa, reason: 'lerp "$f" at t=0');
          expect(spec.lerp(fa, fb, 1), fb, reason: 'lerp "$f" at t=1');
          expect(
            spec.lerp(empty, fb, 1),
            fb,
            reason: 'lerp "$f" from unset at t=1',
          );
        }
        expect(spec.lerp(la, lb, 0), la);
        expect(spec.lerp(la, lb, 1), lb);
        expect(spec.lerp(null, null, 0.5), empty);
        expect(spec.lerp(a, a, 0.5), a);
      });
    });
  }
}
