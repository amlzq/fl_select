import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_panel.dart';
// [CascadingView] is intentionally not part of the public API; these tests are
// in-package, so they reach it through its own library.
import 'package:fl_select/src/select/widgets/cascading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A category whose entries drill down one level, laid out with
/// [SelectCascadingLayout]:
///
/// ```
/// Any
/// East  >  Shanghai / Hangzhou
/// West
/// ```
SelectCategoryEntry<dynamic> _region({
  SelectionMode? categorySelectionMode,
  bool isScrollable = false,
}) => SelectCategoryEntry<dynamic>(
  id: 'region',
  name: 'Region',
  selectionMode: categorySelectionMode,
  layout: SelectCascadingLayout(isScrollable: isScrollable),
  children: {
    SelectTextEntry<dynamic>.any(name: 'Any'),
    SelectTextEntry<dynamic>(
      id: 'east',
      name: 'East',
      children: {
        SelectTextEntry<dynamic>(id: 'sh', name: 'Shanghai'),
        SelectTextEntry<dynamic>(id: 'hz', name: 'Hangzhou'),
      },
    ),
    SelectTextEntry<dynamic>(id: 'west', name: 'West'),
  },
);

Set<SelectEntry<dynamic>> _entries({
  SelectionMode? categorySelectionMode,
  bool cascadingScrollable = false,
}) => {
  _region(
    categorySelectionMode: categorySelectionMode,
    isScrollable: cascadingScrollable,
  ),
};

Widget _harness(
  SelectController controller, {
  SelectionMode selectionMode = SelectionMode.multiple,
  Set<SelectEntry<dynamic>>? entries,
  bool cascadingScrollable = false,
  SelectCascadingViewTheme? cascadingViewTheme,
}) => MaterialApp(
  home: Scaffold(
    body: SelectPanel(
      delegate: TabNavSelectDelegate(
        selectionMode: selectionMode,
        entries: entries ?? _entries(cascadingScrollable: cascadingScrollable),
        cascadingViewTheme: cascadingViewTheme,
      ),
      controller: controller,
    ),
  ),
);

/// A category with labels long enough for the estimated column widths to
/// overflow a narrow viewport, so the horizontal sweep is observable.
Set<SelectEntry<dynamic>> _wideEntries() => {
  SelectCategoryEntry<dynamic>(
    id: 'region',
    name: 'Region',
    layout: const SelectCascadingLayout(isScrollable: true),
    children: {
      SelectTextEntry<dynamic>(
        id: 'ne',
        name: 'Northeast Region',
        children: {
          SelectTextEntry<dynamic>(
            id: 'js',
            name: 'Jiangsu Province',
            children: {
              SelectTextEntry<dynamic>(id: 'nj', name: 'Nanjing City'),
            },
          ),
        },
      ),
      SelectTextEntry<dynamic>(id: 'sw', name: 'Southwest Region'),
    },
  ),
};

/// The cascade's own horizontal scroll view, if the layout made it scrollable.
SingleChildScrollView? _cascadeScrollView(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(CascadingView),
    matching: find.byType(SingleChildScrollView),
  );
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<SingleChildScrollView>(finder);
}

/// A bare [CascadingView] (no panel) so the view's own options — the title, the
/// background ends and the theme fallback — can be exercised directly.
Widget _viewHarness({
  bool showTitle = true,
  bool shrinkWrap = true,
  SelectCascadingViewTheme? theme,
  Color? startBackgroundColor,
  Color? endBackgroundColor,
  int backgroundColorOffset = 0,
}) {
  final category = _region();
  return MaterialApp(
    home: Scaffold(
      body: SelectTheme(
        data: SelectThemeData(ThemeData.light(), cascadingViewTheme: theme),
        child: CascadingView(
          entries: category.children!.toList(),
          category: category,
          selectionMode: SelectionMode.multiple,
          showTitle: showTitle,
          shrinkWrap: shrinkWrap,
          startBackgroundColor: startBackgroundColor,
          backgroundColorOffset: backgroundColorOffset,
          endBackgroundColor: endBackgroundColor,
        ),
      ),
    ),
  );
}

/// The colors of the background ramp used by the color tests.
///
/// `_region` is three levels deep (category -> children -> grandchildren), so
/// the ramp holds one step per painted level and its last step — the deepest
/// column — is always [_endColor].
///
/// Which step a column takes depends on `backgroundColorOffset`: the default `0`
/// puts the first column on the leftmost surface — the ramp start, which is not
/// themeable, so a bare [CascadingView] starts from the panel background
/// ([_panelStartColor]) — while `1` puts it one step in, as the sidebar hosts
/// do.
const _endColor = Color(0xFF506070);
const _overrideStartColor = Color(0xFF607080);
const _overrideEndColor = Color(0xFFA0B0C0);

/// The panel background a bare view falls back to as the ramp start.
final _panelStartColor = SelectThemeData(ThemeData.light()).backgroundColor;

/// The step a column takes with `backgroundColorOffset: 1` on a three-level
/// category.
final _firstColumnColor = Color.lerp(_panelStartColor, _endColor, 0.5)!;
final _overrideFirstColumnColor = Color.lerp(
  _overrideStartColor,
  _overrideEndColor,
  0.5,
)!;

/// The background colors painted by the cascade columns.
List<Color> _columnColors(WidgetTester tester) => tester
    .widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(CascadingView),
        matching: find.byType(ColoredBox),
      ),
    )
    .map((box) => box.color)
    .toList();

void main() {
  group('CascadingView', () {
    testWidgets('shows the category name as a title by default', (
      tester,
    ) async {
      await tester.pumpWidget(_viewHarness());
      await tester.pumpAndSettle();

      expect(find.text('Region'), findsOneWidget);
      // The title defaults to visible even under an unbounded host.
      expect(find.text('East'), findsOneWidget);
    });

    testWidgets('hides the title when showTitle is false', (tester) async {
      await tester.pumpWidget(_viewHarness(showTitle: false));
      await tester.pumpAndSettle();

      expect(find.text('Region'), findsNothing);
      expect(find.text('East'), findsOneWidget);
    });

    testWidgets('makes the first column the leftmost surface of the theme ramp', (
      tester,
    ) async {
      await tester.pumpWidget(
        _viewHarness(
          theme: const SelectCascadingViewTheme(endBackgroundColor: _endColor),
        ),
      );
      await tester.pumpAndSettle();

      // Without an offset the first column is the leftmost surface of the ramp,
      // so it is seamless with the panel background the host renders on and
      // only the deeper columns darken.
      expect(_columnColors(tester), [_panelStartColor]);
    });

    testWidgets('starts the first column one step in at an offset of 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        _viewHarness(
          theme: const SelectCascadingViewTheme(endBackgroundColor: _endColor),
          backgroundColorOffset: 1,
        ),
      );
      await tester.pumpAndSettle();

      // The host painted the category level itself, so the first column takes
      // the middle step of the three-step ramp and the start is not painted.
      expect(_columnColors(tester), contains(_firstColumnColor));
      expect(_columnColors(tester), isNot(contains(_panelStartColor)));
    });

    testWidgets('shifts a custom ramp by the offset as well', (tester) async {
      await tester.pumpWidget(
        _viewHarness(
          startBackgroundColor: _overrideStartColor,
          endBackgroundColor: _overrideEndColor,
          backgroundColorOffset: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(_columnColors(tester), contains(_overrideFirstColumnColor));
      expect(_columnColors(tester), isNot(contains(_overrideStartColor)));
    });

    testWidgets('an end passed to the view wins over the theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _viewHarness(
          theme: const SelectCascadingViewTheme(endBackgroundColor: _endColor),
          startBackgroundColor: _overrideStartColor,
          endBackgroundColor: _overrideEndColor,
        ),
      );
      await tester.pumpAndSettle();

      // Drilling down reveals the deepest column, which is where the ramp ends.
      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(_columnColors(tester), contains(_overrideEndColor));
      expect(_columnColors(tester), isNot(contains(_endColor)));
    });

    testWidgets('a start passed to the view anchors the ramp', (tester) async {
      await tester.pumpWidget(
        _viewHarness(
          startBackgroundColor: _overrideStartColor,
          endBackgroundColor: _endColor,
        ),
      );
      await tester.pumpAndSettle();

      // The first column is the ramp start, so a passed start is painted by it.
      expect(_columnColors(tester), contains(_overrideStartColor));
      expect(_columnColors(tester), isNot(contains(_panelStartColor)));
    });
  });

  group('SelectCascadingLayout isScrollable', () {
    testWidgets('divides the width when the layout is not scrollable', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(_cascadeScrollView(tester), isNull);
    });

    testWidgets('wraps the columns in a horizontal scroll view', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller, cascadingScrollable: true));
      await tester.pumpAndSettle();

      expect(_cascadeScrollView(tester)?.scrollDirection, Axis.horizontal);
    });

    testWidgets('sweeps to the revealed column', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller, entries: _wideEntries()));
      await tester.pumpAndSettle();

      // Drilling down appends a column that overflows the viewport.
      await tester.tap(find.text('Northeast Region'));
      await tester.pumpAndSettle();

      expect(find.text('Jiangsu Province'), findsOneWidget);
      expect(_cascadeScrollView(tester)!.controller!.offset, greaterThan(0));
    });

    testWidgets('stays put under an unbounded host when not scrollable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(find.text('Shanghai'), findsOneWidget);
      expect(_cascadeScrollView(tester), isNull);
    });
  });

  group('SelectCascadingLayout theme', () {
    testWidgets('starts the ramp at the panel background', (tester) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(
        _harness(
          controller,
          cascadingViewTheme: const SelectCascadingViewTheme(
            endBackgroundColor: _endColor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The container has no sidebar, so its cascade's first column is the
      // leftmost surface of the ramp and takes the panel background the layout
      // renders on.
      expect(_columnColors(tester), contains(_panelStartColor));
      expect(_columnColors(tester), isNot(contains(_firstColumnColor)));

      // Drilling down reveals the deepest column, which carries the end of the
      // ramp: the offset shifts the sampling without shortening the ramp.
      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(_columnColors(tester), contains(_endColor));
    });
  });

  group('SelectCascadingLayout', () {
    testWidgets('renders the category children as the first column', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      // The layout branch is the one and only cascading view.
      expect(find.byType(CascadingView), findsOneWidget);

      expect(find.text('Any'), findsOneWidget);
      expect(find.text('East'), findsOneWidget);
      expect(find.text('West'), findsOneWidget);
      // Deeper levels stay collapsed until a branch is tapped.
      expect(find.text('Shanghai'), findsNothing);
      expect(find.text('Hangzhou'), findsNothing);
    });

    testWidgets('tapping a branch appends a column and a leaf selects', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(find.text('Shanghai'), findsOneWidget);
      expect(find.text('Hangzhou'), findsOneWidget);

      await tester.tap(find.text('Shanghai'));
      await tester.pumpAndSettle();

      // The leaf lives one level below the category, so it is level 2.
      expect(
        controller.selectedEntriesAtLevel(2).map((e) => e.id),
        contains('sh'),
      );
    });

    testWidgets('an Any leaf in a parent column trims the deeper levels', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shanghai'));
      await tester.pumpAndSettle();
      expect(controller.selectedEntriesAtLevel(2), isNotEmpty);

      // Jumping back to "Any" drops everything selected below the first level.
      await tester.tap(find.text('Any'));
      await tester.pumpAndSettle();

      expect(controller.selectedEntriesAtLevel(2), isEmpty);
      expect(find.text('Shanghai'), findsNothing);
    });

    testWidgets('keeps the expanded column across a host rebuild', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();
      expect(find.text('Shanghai'), findsOneWidget);

      // A pending selection rebuilds the host; the cascade navigation state
      // must survive it.
      await tester.tap(find.text('Shanghai'));
      await tester.pumpAndSettle();
      expect(find.text('Shanghai'), findsOneWidget);
    });

    testWidgets('applies a single-mode leaf immediately', (tester) async {
      final controller = SelectController(selectionMode: SelectionMode.single);
      await tester.pumpWidget(
        _harness(
          controller,
          selectionMode: SelectionMode.single,
          entries: _entries(categorySelectionMode: SelectionMode.single),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shanghai'));
      await tester.pumpAndSettle();

      expect(
        controller.selectedEntriesAtLevel(2).map((e) => e.id),
        equals(<String>['sh']),
      );
    });
  });
}
