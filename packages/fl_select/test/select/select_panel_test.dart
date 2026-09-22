import 'dart:async';

import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_panel.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _amber = Color(0xFFECC104);
const _teal = Color(0xFF00796B);
const _ambientPadding = EdgeInsets.fromLTRB(1, 2, 3, 4);

Set<SelectEntry> get _flatEntries => {
  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
  SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
};

/// Wraps [panel] in a [SelectTheme] when [selectTheme] is provided.
///
/// This mirrors how the overlay host injects the trigger's resolved theme:
/// the overlay lives outside the trigger's subtree, so the theme is passed
/// down as an inherited widget instead of a parameter.
Widget _themedPanel(Widget panel, SelectThemeData? selectTheme) {
  if (selectTheme == null) {
    return panel;
  }
  return SelectTheme(data: selectTheme, child: panel);
}

/// Returns the [SelectThemeData] the panel injected below itself, i.e. after
/// merging the delegate-level theme fields over the ambient theme.
SelectThemeData _injectedTheme(WidgetTester tester) {
  return tester
      .widget<SelectTheme>(
        find.descendant(
          of: find.byType(SelectPanel),
          matching: find.byType(SelectTheme),
        ),
      )
      .data;
}

/// A minimal [SelectDelegate] used to drive [SelectPanel] rendering and to
/// capture the active controller for assertions.
class _TestDelegate extends SelectDelegate {
  _TestDelegate({
    required this.bodyBuilder,
    required super.entriesLoader,
    super.selectedEntriesLoader,
    super.errorBuilder,
  });

  final Widget Function(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  )
  bodyBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected, {
    String searchQuery = '',
  }) => bodyBuilder(context, entries, previousSelected);

  @override
  Widget buildSkeleton(BuildContext context) =>
      skeletonBuilder?.call(context) ?? const Text('skeleton');
}

void main() {
  group('SelectWrapViewTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectWrapViewTheme(chipColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectWrapViewTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
      );
      final merged = base.merge(
        const SelectWrapViewTheme(selectedChipColor: _amber),
      );
      expect(merged.selectedChipColor, _amber);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.padding, _ambientPadding);
      expect(merged.variant, isNull);
    });
  });

  group('SelectWrapViewTheme.lerp', () {
    test('picks the variant of the nearer endpoint', () {
      const filled = SelectWrapViewTheme(variant: SelectChipVariant.filled);
      const outlined = SelectWrapViewTheme(variant: SelectChipVariant.outlined);

      expect(
        SelectWrapViewTheme.lerp(filled, outlined, 0.25).variant,
        SelectChipVariant.filled,
      );
      expect(
        SelectWrapViewTheme.lerp(filled, outlined, 0.75).variant,
        SelectChipVariant.outlined,
      );
    });

    test('interpolates colors', () {
      const black = SelectWrapViewTheme(backgroundColor: Colors.black);
      const white = SelectWrapViewTheme(backgroundColor: Colors.white);

      expect(SelectWrapViewTheme.lerp(black, white, 0).backgroundColor!.r, 0);
      expect(
        SelectWrapViewTheme.lerp(black, white, 0.5).backgroundColor!.r,
        0.5,
      );
      expect(SelectWrapViewTheme.lerp(black, white, 1).backgroundColor!.r, 1);
    });
  });

  group('SelectPanel wrapViewTheme injection', () {
    Finder wrapViewContainer(Color color) =>
        find.byWidgetPredicate((w) => w is Container && w.color == color);

    Widget wrapViewPanelHarness({
      SelectChipBarTheme? delegateChipBarTheme,
      SelectWrapViewTheme? delegateWrapViewTheme,
      SelectThemeData? selectTheme,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                chipBarTheme: delegateChipBarTheme,
                wrapViewTheme: delegateWrapViewTheme,
              ),
            ),
            selectTheme,
          ),
        ),
      );
    }

    testWidgets('delegate wrapViewTheme.backgroundColor styles the wrap view', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapViewPanelHarness(
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(wrapViewContainer(_amber), findsOneWidget);
    });

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapViewPanelHarness(
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            wrapViewTheme: const SelectWrapViewTheme(padding: _ambientPadding),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delegate's backgroundColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.color == _amber &&
              w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapViewPanelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            wrapViewTheme: const SelectWrapViewTheme(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(wrapViewContainer(Colors.teal), findsOneWidget);
    });

    testWidgets('wrapViewTheme wins over the legacy chipBarTheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapViewPanelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: Colors.teal,
          ),
          delegateWrapViewTheme: const SelectWrapViewTheme(
            backgroundColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(wrapViewContainer(_amber), findsOneWidget);
      expect(wrapViewContainer(Colors.teal), findsNothing);
    });

    testWidgets('legacy chipBarTheme still reaches the wrap view', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapViewPanelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: Colors.teal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(wrapViewContainer(Colors.teal), findsOneWidget);
    });
  });

  group('SelectWrapView theme ownership', () {
    testWidgets('the wrap view resolves its own theme outside a SelectPanel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTheme(
            data: SelectThemeData(
              ThemeData.light(),
              chipBarTheme: const SelectChipBarTheme(
                backgroundColor: Colors.teal,
              ),
            ),
            child: Scaffold(
              body: SelectWrapView(
                entries: _flatEntries.toList(),
                onChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only SelectPanel folds the legacy chipBarTheme into the wrap view
      // theme; the wrap view itself never reads SelectChipBarTheme, so an
      // ambient chip theme alone leaves its chips on their own defaults.
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == Colors.teal),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == Colors.transparent,
        ),
        findsOneWidget,
      );
    });
  });

  group('SelectGridTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectGridTileTheme(variant: SelectGridTileVariant.filled);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectGridTileTheme(
        variant: SelectGridTileVariant.filled,
        tileColor: Colors.blue,
      );
      final merged = base.merge(
        const SelectGridTileTheme(selectedTileColor: _amber),
      );
      expect(merged.selectedTileColor, _amber);
      expect(merged.variant, SelectGridTileVariant.filled);
      expect(merged.tileColor, Colors.blue);
    });
  });

  group('SelectFieldTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectFieldTileTheme(
        variant: SelectFieldTileVariant.outlined,
      );
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectFieldTileTheme(
        variant: SelectFieldTileVariant.outlined,
        textColor: Colors.blue,
      );
      final merged = base.merge(
        const SelectFieldTileTheme(selectedColor: _amber),
      );
      expect(merged.selectedColor, _amber);
      expect(merged.variant, SelectFieldTileVariant.outlined);
      expect(merged.textColor, Colors.blue);
    });
  });

  group('SelectSideBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectSideBarTheme(width: 120);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectSideBarTheme(width: 120, backgroundColor: Colors.blue);
      final merged = base.merge(const SelectSideBarTheme(width: 88));
      expect(merged.width, 88);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.selectedColor, isNull);
    });
  });

  group('SelectPanel tile/sideBar theme injection', () {
    /// Pumps a panel whose delegate supplies the given theme overrides and
    /// returns the [SelectThemeData] [SelectPanel] injected into the tree.
    Future<SelectThemeData> tileSideEffectiveTheme(
      WidgetTester tester, {
      SelectThemeData? selectTheme,
      SelectGridTileTheme? gridTileTheme,
      SelectFieldTileTheme? fieldTileTheme,
      SelectSideBarTheme? sideBarTheme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _themedPanel(
              SelectPanel(
                delegate: WrapSelectDelegate(
                  selectionMode: SelectionMode.multiple,
                  entries: _flatEntries,
                  gridTileTheme: gridTileTheme,
                  fieldTileTheme: fieldTileTheme,
                  sideBarTheme: sideBarTheme,
                ),
              ),
              selectTheme,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return _injectedTheme(tester);
    }

    testWidgets('gridTileTheme', (tester) async {
      final theme = await tileSideEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          gridTileTheme: const SelectGridTileTheme(tileColor: Colors.blue),
        ),
        gridTileTheme: const SelectGridTileTheme(
          variant: SelectGridTileVariant.outlined,
        ),
      );
      expect(theme.gridTileTheme.variant, SelectGridTileVariant.outlined);
      expect(theme.gridTileTheme.tileColor, Colors.blue);
    });

    testWidgets('fieldTileTheme', (tester) async {
      final theme = await tileSideEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          fieldTileTheme: const SelectFieldTileTheme(textColor: Colors.blue),
        ),
        fieldTileTheme: const SelectFieldTileTheme(
          variant: SelectFieldTileVariant.outlined,
        ),
      );
      expect(theme.fieldTileTheme.variant, SelectFieldTileVariant.outlined);
      expect(theme.fieldTileTheme.textColor, Colors.blue);
    });

    testWidgets('sideBarTheme', (tester) async {
      final theme = await tileSideEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          sideBarTheme: const SelectSideBarTheme(padding: _ambientPadding),
        ),
        sideBarTheme: const SelectSideBarTheme(width: 88),
      );
      expect(theme.sideBarTheme.width, 88);
      expect(theme.sideBarTheme.padding, _ambientPadding);
    });
  });

  group('SelectPanelTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectPanelTheme(elevation: 4);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectPanelTheme(elevation: 4, shape: null);
      final merged = base.merge(const SelectPanelTheme(shadowColor: _amber));
      expect(merged.shadowColor, _amber);
      expect(merged.elevation, 4);
      expect(merged.clipBehavior, isNull);
    });
  });

  group('SelectTabBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectTabBarTheme(indicatorHeight: 3);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectTabBarTheme(padding: _ambientPadding);
      final merged = base.merge(
        const SelectTabBarTheme(backgroundColor: _amber),
      );
      expect(merged.backgroundColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.indicatorColor, isNull);
    });
  });

  group('SelectListTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectListTileTheme(tileColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectListTileTheme(textColor: _amber);
      final merged = base.merge(
        const SelectListTileTheme(selectedColor: _amber),
      );
      expect(merged.selectedColor, _amber);
      expect(merged.textColor, _amber);
      expect(merged.labelStyle, isNull);
    });
  });

  group('SelectExpansionTileTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectExpansionTileTheme(titlePadding: _ambientPadding);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectExpansionTileTheme(titlePadding: _ambientPadding);
      final merged = base.merge(
        const SelectExpansionTileTheme(selectedColor: _amber),
      );
      expect(merged.selectedColor, _amber);
      expect(merged.titlePadding, _ambientPadding);
      expect(merged.animationDuration, isNull);
    });
  });

  group('SelectPanel theme injection (delegate merges over ambient)', () {
    final ambientShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    Widget injectionPanelHarness({SelectThemeData? selectTheme}) {
      return MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
              ),
            ),
            selectTheme,
          ),
        ),
      );
    }

    /// Pumps the harness and returns the [SelectThemeData] that [SelectPanel]
    /// injected into the tree (i.e. after merging delegate-level themes).
    Future<SelectThemeData> injectionEffectiveTheme(
      WidgetTester tester, {
      SelectThemeData? selectTheme,
      required SelectDelegate delegate,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _themedPanel(SelectPanel(delegate: delegate), selectTheme),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return _injectedTheme(tester);
    }

    testWidgets('panelTheme', (tester) async {
      final theme = await injectionEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          panelTheme: SelectPanelTheme(shape: ambientShape),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          panelTheme: const SelectPanelTheme(elevation: 4),
        ),
      );
      expect(theme.panelTheme.elevation, 4);
      expect(theme.panelTheme.shape, ambientShape);
    });

    testWidgets('tabBarTheme', (tester) async {
      final theme = await injectionEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          tabBarTheme: const SelectTabBarTheme(padding: _ambientPadding),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          tabBarTheme: const SelectTabBarTheme(backgroundColor: _amber),
        ),
      );
      expect(theme.tabBarTheme.backgroundColor, _amber);
      expect(theme.tabBarTheme.padding, _ambientPadding);
    });

    testWidgets('listTileTheme', (tester) async {
      final theme = await injectionEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          listTileTheme: const SelectListTileTheme(textColor: _amber),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          listTileTheme: const SelectListTileTheme(selectedColor: _amber),
        ),
      );
      expect(theme.listTileTheme.selectedColor, _amber);
      expect(theme.listTileTheme.textColor, _amber);
    });

    testWidgets('expansionTileTheme', (tester) async {
      final theme = await injectionEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          expansionTileTheme: const SelectExpansionTileTheme(
            titlePadding: _ambientPadding,
          ),
        ),
        delegate: WrapSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entries: _flatEntries,
          expansionTileTheme: const SelectExpansionTileTheme(
            selectedColor: _amber,
          ),
        ),
      );
      expect(theme.expansionTileTheme.selectedColor, _amber);
      expect(theme.expansionTileTheme.titlePadding, _ambientPadding);
    });

    testWidgets('delegate panelTheme renders an elevated Material', (
      tester,
    ) async {
      await tester.pumpWidget(injectionPanelHarness());
      await tester.pumpAndSettle();
      // Sanity check on top of the capture-based tests above: the merged
      // panelTheme must actually reach the rendered panel decoration.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                panelTheme: const SelectPanelTheme(elevation: 6),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Material && w.elevation == 6),
        findsOneWidget,
      );
    });
  });

  group('SelectSearchBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectSearchBarTheme(borderRadius: 8);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectSearchBarTheme(
        padding: _ambientPadding,
        borderRadius: 8,
        iconSize: 20,
      );
      final merged = base.merge(const SelectSearchBarTheme(fillColor: _amber));
      expect(merged.fillColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.borderRadius, 8);
      expect(merged.iconSize, 20);
      expect(merged.filled, isNull);
    });
  });

  group('SelectPanel searchBarTheme injection', () {
    Widget searchBarPanelHarness({
      SelectSearchBarTheme? delegateSearchBarTheme,
      SelectThemeData? selectTheme,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                searchEnabled: true,
                searchBarTheme: delegateSearchBarTheme,
              ),
            ),
            selectTheme,
          ),
        ),
      );
    }

    testWidgets('delegate searchBarTheme.fillColor styles the search bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        searchBarPanelHarness(
          delegateSearchBarTheme: const SelectSearchBarTheme(
            filled: true,
            fillColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectSearchBar), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, _amber);
    });

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        searchBarPanelHarness(
          delegateSearchBarTheme: const SelectSearchBarTheme(
            filled: true,
            fillColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            searchBarTheme: const SelectSearchBarTheme(
              padding: _ambientPadding,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delegate's fillColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectSearchBar), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, _amber);
      expect(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        searchBarPanelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            searchBarTheme: const SelectSearchBarTheme(
              filled: true,
              fillColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, Colors.teal);
    });
  });

  group('SelectRangeSliderTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectRangeSliderTheme(trackHeight: 4);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectRangeSliderTheme(trackHeight: 4, thumbRadius: 10);
      final merged = base.merge(
        const SelectRangeSliderTheme(activeTrackColor: _amber),
      );
      expect(merged.activeTrackColor, _amber);
      expect(merged.trackHeight, 4);
      expect(merged.thumbRadius, 10);
      expect(merged.endLabelStyle, isNull);
    });
  });

  /// Pumps a panel whose delegate supplies the given overrides and returns the
  /// [SelectThemeData] [SelectPanel] injected into the tree.
  Future<SelectThemeData> rangeColorEffectiveTheme(
    WidgetTester tester, {
    SelectThemeData? selectTheme,
    Color? selectedColor,
    Color? backgroundColorHigh,
    SelectRangeSliderTheme? rangeSliderTheme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                selectedColor: selectedColor,
                backgroundColorHigh: backgroundColorHigh,
                rangeSliderTheme: rangeSliderTheme,
              ),
            ),
            selectTheme,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _injectedTheme(tester);
    }

  group('SelectPanel rangeSliderTheme injection', () {
    testWidgets('delegate rangeSliderTheme merges over ambient', (
      tester,
    ) async {
      final theme = await rangeColorEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          rangeSliderTheme: const SelectRangeSliderTheme(trackHeight: 4),
        ),
        rangeSliderTheme: const SelectRangeSliderTheme(thumbRadius: 12),
      );
      expect(theme.rangeSliderTheme.thumbRadius, 12);
      expect(theme.rangeSliderTheme.trackHeight, 4);
    });
  });

  group('SelectPanel loose color injection', () {
    testWidgets('delegate selectedColor overrides ambient', (tester) async {
      final theme = await rangeColorEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(ThemeData.light(), selectedColor: _teal),
        selectedColor: _amber,
      );
      expect(theme.selectedColor, _amber);
    });

    testWidgets('ambient color applies when delegate supplies none', (
      tester,
    ) async {
      final theme = await rangeColorEffectiveTheme(
        tester,
        selectTheme: SelectThemeData(
          ThemeData.light(),
          backgroundColorHigh: _teal,
        ),
      );
      expect(theme.backgroundColorHigh, _teal);
    });

    testWidgets('Material fallback applies when neither supplies one', (
      tester,
    ) async {
      final theme = await rangeColorEffectiveTheme(tester);
      expect(theme.selectedColor, isNotNull);
    });
  });

  group('SelectChipBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectChipBarTheme(chipColor: _amber);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectChipBarTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
      );
      final merged = base.merge(
        const SelectChipBarTheme(selectedChipColor: _amber),
      );
      expect(merged.selectedChipColor, _amber);
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.padding, _ambientPadding);
      expect(merged.variant, isNull);
    });
  });

  group('SelectPanel chipBarTheme injection', () {
    Widget chipBarPanelHarness({
      SelectChipBarTheme? delegateChipBarTheme,
      SelectThemeData? selectTheme,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                chipBarTheme: delegateChipBarTheme,
              ),
            ),
            selectTheme,
          ),
        ),
      );
    }

    testWidgets('delegate chipBarTheme.backgroundColor styles the wrap view', (
      tester,
    ) async {
      await tester.pumpWidget(
        chipBarPanelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: _amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == _amber),
        findsOneWidget,
      );
    });

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        chipBarPanelHarness(
          delegateChipBarTheme: const SelectChipBarTheme(
            backgroundColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            chipBarTheme: const SelectChipBarTheme(padding: _ambientPadding),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delegate's backgroundColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.color == _amber &&
              w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        chipBarPanelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            chipBarTheme: const SelectChipBarTheme(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == Colors.teal),
        findsOneWidget,
      );
    });
  });

  group('SelectActionBarTheme.merge', () {
    test('returns this when other is null', () {
      const base = SelectActionBarTheme(resetFlex: 3);
      expect(base.merge(null), same(base));
    });

    test('overrides only the fields set on other', () {
      const base = SelectActionBarTheme(
        backgroundColor: Colors.blue,
        padding: _ambientPadding,
        resetFlex: 3,
      );
      final merged = base.merge(
        const SelectActionBarTheme(backgroundColor: _amber),
      );
      expect(merged.backgroundColor, _amber);
      expect(merged.padding, _ambientPadding);
      expect(merged.resetFlex, 3);
      expect(merged.applyFlex, isNull);
    });
  });

  group('SelectPanel actionBarTheme injection', () {
    Widget actionBarPanelHarness({
      SelectActionBarTheme? delegateActionBarTheme,
      SelectThemeData? selectTheme,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _themedPanel(
            SelectPanel(
              delegate: WrapSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: _flatEntries,
                actionBarTheme: delegateActionBarTheme,
              ),
            ),
            selectTheme,
          ),
        ),
      );
    }

    testWidgets(
      'delegate actionBarTheme.backgroundColor styles the action bar',
      (tester) async {
        await tester.pumpWidget(
          actionBarPanelHarness(
            delegateActionBarTheme: const SelectActionBarTheme(
              backgroundColor: _amber,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SelectActionBar), findsOneWidget);
        expect(
          find.byWidgetPredicate((w) => w is Container && w.color == _amber),
          findsOneWidget,
        );
      },
    );

    testWidgets('delegate theme merges field-wise over the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        actionBarPanelHarness(
          delegateActionBarTheme: const SelectActionBarTheme(
            backgroundColor: _amber,
          ),
          selectTheme: SelectThemeData(
            ThemeData.light(),
            actionBarTheme: const SelectActionBarTheme(
              padding: _ambientPadding,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delegate's backgroundColor wins while the ambient padding is
      // preserved instead of falling back to the default.
      expect(find.byType(SelectActionBar), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.color == _amber &&
              w.padding == _ambientPadding,
        ),
        findsOneWidget,
      );
    });

    testWidgets('ambient theme applies when delegate supplies none', (
      tester,
    ) async {
      await tester.pumpWidget(
        actionBarPanelHarness(
          selectTheme: SelectThemeData(
            ThemeData.light(),
            actionBarTheme: const SelectActionBarTheme(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == Colors.teal),
        findsOneWidget,
      );
    });
  });

  group('SelectPanel', () {
    testWidgets('shows the skeleton while data is loading', (tester) async {
      final completer = Completer<SelectEntries>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () => completer.future,
                bodyBuilder: (_, _, _) => const Text('body'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('skeleton'), findsOneWidget);
      expect(find.text('body'), findsNothing);

      completer.complete(<SelectEntry>{});
      await tester.pumpAndSettle();
      expect(find.text('skeleton'), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('shows the body once data is available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                },
                bodyBuilder: (context, entries, _) =>
                    Text('entries:${entries.length}'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('entries:1'), findsOneWidget);
    });

    testWidgets('shows an error message when data fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => throw Exception('boom'),
                bodyBuilder: (_, _, _) => const Text('body'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets(
      'shows an error when a two-level structure has a mismatched parentId instead of hanging',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectPanel(
                delegate: _TestDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectCategoryEntry<dynamic>(
                      id: 'c1',
                      name: 'Cate 1',
                      children: {
                        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                      },
                    ),
                  },
                  bodyBuilder: (_, _, _) => const Text('body'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        // The build-phase ArgumentError is routed through the error UI.
        expect(find.text('body'), findsNothing);
        expect(find.textContaining('Error:'), findsOneWidget);
        // And it is reported to the console; consume it so the test passes.
        expect(tester.takeException(), isNotNull);
      },
    );

    testWidgets(
      'uses errorBuilder for a two-level structure with a mismatched parentId',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectPanel(
                delegate: _TestDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectCategoryEntry<dynamic>(
                      id: 'c1',
                      name: 'Cate 1',
                      children: {
                        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                      },
                    ),
                  },
                  bodyBuilder: (_, _, _) => const Text('body'),
                  errorBuilder: (error, _) => Text('custom: $error'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('body'), findsNothing);
        expect(find.textContaining('custom:'), findsOneWidget);
        expect(tester.takeException(), isNotNull);
      },
    );

    testWidgets('uses errorBuilder when data fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => throw Exception('boom'),
                bodyBuilder: (_, _, _) => const Text('body'),
                errorBuilder: (error, _) => Text('custom: $error'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
      expect(find.text('custom: Exception: boom'), findsOneWidget);
    });

    testWidgets('forwards callbacks with an external controller', (
      tester,
    ) async {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var changed = false;
      var applied = false;
      var reset = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, _, _) => const SizedBox(),
              ),
              controller: controller,
              onChangeTap: (_) => changed = true,
              onApplyTap: (_) => applied = true,
              onResetTap: () => reset = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.change(<SelectEntry>{});
      controller.apply(<SelectEntry>{});
      controller.reset();

      expect(changed, isTrue);
      expect(applied, isTrue);
      expect(reset, isTrue);
    });

    testWidgets('forwards callbacks with an internal controller', (
      tester,
    ) async {
      SelectController? captured;
      var changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (context, _, _) {
                  captured = SelectController.of(context);
                  return const SizedBox();
                },
              ),
              onChangeTap: (_) => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      captured!.change(<SelectEntry>{});
      expect(changed, isTrue);
    });

    testWidgets('does not dispose an externally-provided controller', (
      tester,
    ) async {
      final controller = SelectController(selectionMode: SelectionMode.single);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, _, _) => const SizedBox(),
              ),
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.isDisposed, isFalse);
    });

    testWidgets('disposes its own internal controller', (tester) async {
      SelectController? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (context, _, _) {
                  captured = SelectController.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(captured!.isDisposed, isTrue);
    });

    testWidgets('re-registers forwarding listeners when controller changes', (
      tester,
    ) async {
      final first = SelectController(selectionMode: SelectionMode.single);
      final second = SelectController(selectionMode: SelectionMode.single);
      var appliedOnFirst = false;
      var appliedOnSecond = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, _, _) => const SizedBox(),
              ),
              controller: first,
              onApplyTap: (_) => appliedOnFirst = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap to a new external controller.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, _, _) => const SizedBox(),
              ),
              controller: second,
              onApplyTap: (_) => appliedOnSecond = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The first controller must not have been disposed by the panel, and the
      // second controller's callbacks must now fire.
      expect(first.isDisposed, isFalse);
      second.apply(<SelectEntry>{});
      expect(appliedOnSecond, isTrue);
      expect(appliedOnFirst, isFalse);
    });

    testWidgets('initializes the internal controller from delegate state', (
      tester,
    ) async {
      SelectController? captured;
      final previous = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                selectedEntriesLoader: () => previous,
                bodyBuilder: (context, _, _) {
                  captured = SelectController.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.selectedEntries, isNotNull);
      expect(captured!.selectedEntries!.any((e) => e.id == 'a'), isTrue);
    });
  });

  group('SelectPanel height shrink-wrap', () {
    Widget host({required double bodyHeight, double maxHeight = 600}) =>
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SelectPanel(
                  delegate: _TestDelegate(
                    entriesLoader: () async => <SelectEntry<dynamic>>{},
                    bodyBuilder: (_, _, _) => SizedBox(height: bodyHeight),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('shrinks to its content height within a loose bounded '
        'constraint instead of stretching to the cap', (tester) async {
      await tester.pumpWidget(host(bodyHeight: 100));
      await tester.pumpAndSettle();

      final height = tester.getSize(find.byType(SelectPanel)).height;
      // Mirrors Flexible(fit: loose) in dialog/bottom-sheet hosts: the panel
      // previously stretched to the 600px cap; it must now wrap its content.
      expect(height, closeTo(100, 0.1));
    });

    testWidgets('caps at the incoming maxHeight when content is taller', (
      tester,
    ) async {
      await tester.pumpWidget(host(bodyHeight: 5000));
      await tester.pumpAndSettle();

      final height = tester.getSize(find.byType(SelectPanel)).height;
      expect(height, closeTo(600, 0.1));
    });
  });
}
