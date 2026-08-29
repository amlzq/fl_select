import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PopupSelectBar', () {
    testWidgets('toggles overlay and indicator on tap', (tester) async {
      var showed = false;
      var hidden = false;
      final controller = PopupSelectController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: const [
                PopupTab(label: 'Filter'),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                  },
                ),
              ],
              onSelectShowed: (_) => showed = true,
              onSelectHidden: (_) => hidden = true,
              onApplied: (_, __) {},
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      expect(controller.isSelectShowing, isFalse);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(showed, isTrue);
      expect(controller.isSelectShowing, isTrue);
      // The default indicator (Icons.arrow_drop_down) rotates 180° to point up
      // while expanded; the icon data is unchanged, so assert on the rotation
      // rather than on a swapped Icons.arrow_drop_up widget.
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      final expandedRotation = tester.widget<RotationTransition>(
        find.descendant(
          of: find.byType(PopupTab),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(expandedRotation.turns.value, 0.5);
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(hidden, isTrue);
      expect(controller.isSelectShowing, isFalse);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      final collapsedRotation = tester.widget<RotationTransition>(
        find.descendant(
          of: find.byType(PopupTab),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(collapsedRotation.turns.value, 0.0);
    });

    testWidgets('applies selection and updates tab label', (tester) async {
      ({PopupTabData tabData, SelectEntries selected})? applied;
      final controller = PopupSelectController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: const [
                PopupTab(label: 'Sort'),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                    SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
                  },
                ),
              ],
              onApplied: (tabData, selected) =>
                  applied = (tabData: tabData, selected: selected),
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isFalse);
      expect(find.text('Sort'), findsNothing);
      expect(find.text('A'), findsOneWidget);

      expect(applied, isNotNull);
      expect(applied!.selected.any((e) => e.id == 'a'), isTrue);
    });

    testWidgets('uses labelGetter when provided', (tester) async {
      ({PopupTabData tabData, SelectEntries selected})? applied;
      final controller = PopupSelectController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: [
                PopupTab(
                  label: 'Price',
                  labelLoader: (selected) => 'Custom',
                ),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                  },
                ),
              ],
              onApplied: (tabData, selected) =>
                  applied = (tabData: tabData, selected: selected),
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isFalse);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Price'), findsNothing);
      expect(applied, isNotNull);
    });

    testWidgets('fires onChanged and onReset in multiple selection',
        (tester) async {
      ({PopupTabData tabData, SelectEntries selected})? changed;
      var resetCalled = false;
      final controller = PopupSelectController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: const [
                PopupTab(label: 'Multi'),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  selectionMode: SelectionMode.multiple,
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                    SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
                  },
                ),
              ],
              onChanged: (tabData, selected) =>
                  changed = (tabData: tabData, selected: selected),
              onApplied: (_, __) {},
              onReset: () => resetCalled = true,
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      await tester.tap(find.text('Multi'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(changed, isNotNull);
      expect(changed!.selected.any((e) => e.id == 'a'), isTrue);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(resetCalled, isTrue);
    });

    testWidgets('centers the selected tab when isScrollable', (tester) async {
      final controller = PopupSelectController();

      Widget buildBar() => MaterialApp(
            home: Scaffold(
              appBar: PopupSelectBar(
                isScrollable: true,
                tabs: [
                  for (var i = 0; i < 12; i++) PopupTab(label: 'Filter $i')
                ],
                selectDelegates: [
                  for (var i = 0; i < 12; i++)
                    ListSelectDelegate(
                      entriesLoader: () async => <SelectEntry<dynamic>>{
                        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                      },
                    ),
                ],
                onApplied: (_, __) {},
                controller: controller,
              ),
              body: const SizedBox.expand(),
            ),
          );

      await tester.pumpWidget(buildBar());

      double offset() => tester
          .widget<SingleChildScrollView>(find.descendant(
              of: find.byType(PopupSelectBar),
              matching: find.byType(SingleChildScrollView)))
          .controller!
          .offset;

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(offset(), 0.0);

      // Selecting a fully-visible tab still centers it ("center on select",
      // matching Flutter's TabBar), rather than minimally revealing it.
      // Filter 4 is fully visible right of the center, so centering it
      // requires a positive offset; tabs near the start clamp to 0.
      final rectBefore = tester.getRect(find.text('Filter 4'));
      await tester.tap(find.text('Filter 4'));
      await tester.pumpAndSettle();

      final rectAfter = tester.getRect(find.text('Filter 4'));
      // The bar scrolled: the tab moved and is now centered on the 800px-wide
      // test surface (dx = 400).
      expect(rectAfter.left, lessThan(rectBefore.left));
      expect(rectAfter.center.dx, closeTo(400, 30));

      // Collapsing the panel does not re-scroll...
      final double centeredDx = rectAfter.center.dx;
      await tester.tap(find.text('Filter 4'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Filter 4')).center.dx, centeredDx);

      // ...and reopening the same tab doesn't either.
      await tester.tap(find.text('Filter 4'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Filter 4')).center.dx, centeredDx);
    });

    testWidgets('apply() centers the tab only when centerTab is true',
        (tester) async {
      final controller = PopupSelectController();

      Widget buildBar() => MaterialApp(
            home: Scaffold(
              appBar: PopupSelectBar(
                isScrollable: true,
                tabs: [
                  for (var i = 0; i < 12; i++) PopupTab(label: 'Filter $i')
                ],
                selectDelegates: [
                  for (var i = 0; i < 12; i++)
                    ListSelectDelegate(
                      entriesLoader: () async => <SelectEntry<dynamic>>{
                        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                      },
                    ),
                ],
                onApplied: (_, __) {},
                controller: controller,
              ),
              body: const SizedBox.expand(),
            ),
          );

      await tester.pumpWidget(buildBar());

      double offset() => tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!
          .offset;

      // Default: apply() does not scroll the bar.
      var ok = await controller.apply(tabIndex: 6, selectedEntryIds: {'a'});
      expect(ok, isTrue);
      await tester.pumpAndSettle();
      expect(offset(), 0.0);
      // Filter 6's label became the applied result.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Filter 6'), findsNothing);

      // centerTab: true scrolls the applied tab to the center.
      ok = await controller.apply(
          tabIndex: 8, selectedEntryIds: {'a'}, centerTab: true);
      expect(ok, isTrue);
      await tester.pumpAndSettle();
      expect(offset(), greaterThan(0.0));
    });

    testWidgets('isScrollable=false renders a non-scrollable row',
        (tester) async {
      final controller = PopupSelectController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: const [
                PopupTab(label: 'Filter'),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                  },
                ),
              ],
              onApplied: (_, __) {},
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(controller.isSelectShowing, isTrue);
    });
  });
}
