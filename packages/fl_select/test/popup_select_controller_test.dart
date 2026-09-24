import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [PopupSelectController] behavior driven directly through
/// its public API (rather than via simulated taps). The real [PopupSelectBar]
/// widget is mounted only to wire up the ticker provider, tab data and selector
/// delegates the controller depends on; assertions then call
/// `controller.toggleSelect` / `controller.hideSelect` directly.
SelectEntries _restorationEntries(String id) => <SelectEntry<dynamic>>{
  SelectTextEntry<dynamic>(id: id, name: id.toUpperCase()),
};

void main() {
  group('PopupSelectController', () {
    Future<void> pumpBar(
      WidgetTester tester,
      PopupSelectController controller,
      List<PopupTab> tabs,
      List<SelectDelegate> delegates,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: tabs,
              selectDelegates: delegates,
              onApplied: (_, _) {},
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
    }

    testWidgets('toggleSelect opens the requested panel', (tester) async {
      final controller = PopupSelectController();
      await pumpBar(
        tester,
        controller,
        const [PopupTab(label: 'T0'), PopupTab(label: 'T1')],
        [
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a0', name: 'A0'),
            },
          ),
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a1', name: 'A1'),
            },
          ),
        ],
      );

      controller.toggleSelect(index: 0);
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(controller.currentIndex, 0);
      // The panel binds to tab 0's delegate and renders its entries.
      expect(find.text('A0'), findsOneWidget);
      expect(controller.selectController, isNotNull);
    });

    testWidgets(
      'toggleSelect switches to another open panel without closing the '
      'overlay and renders the new panel content',
      (tester) async {
        final controller = PopupSelectController();
        await pumpBar(
          tester,
          controller,
          const [PopupTab(label: 'T0'), PopupTab(label: 'T1')],
          [
            ListSelectDelegate(
              entriesLoader: () async => {
                SelectTextEntry<dynamic>(id: 'a0', name: 'A0'),
              },
            ),
            ListSelectDelegate(
              entriesLoader: () async => {
                SelectTextEntry<dynamic>(id: 'a1', name: 'A1'),
              },
            ),
          ],
        );

        // Open panel 0 first.
        controller.toggleSelect(index: 0);
        await tester.pumpAndSettle();
        expect(controller.currentIndex, 0);
        expect(find.text('A0'), findsOneWidget);

        // While panel 0 is open, switch to panel 1 programmatically.
        controller.toggleSelect(index: 1);
        await tester.pumpAndSettle();

        // The overlay must stay open (no collapse/reopen) and show panel 1.
        expect(controller.isSelectShowing, isTrue);
        expect(controller.currentIndex, 1);
        expect(find.text('A1'), findsOneWidget);
        // The previous panel's content is gone.
        expect(find.text('A0'), findsNothing);
      },
    );

    testWidgets('toggleSelect on the already-open panel closes it', (
      tester,
    ) async {
      final controller = PopupSelectController();
      await pumpBar(
        tester,
        controller,
        const [PopupTab(label: 'T0'), PopupTab(label: 'T1')],
        [
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a0', name: 'A0'),
            },
          ),
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a1', name: 'A1'),
            },
          ),
        ],
      );

      controller.toggleSelect(index: 1);
      await tester.pumpAndSettle();
      expect(controller.isSelectShowing, isTrue);
      expect(controller.currentIndex, 1);

      // Tapping the same (open) index toggles it closed.
      controller.toggleSelect(index: 1);
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isFalse);
    });

    testWidgets('hideSelect closes an open overlay', (tester) async {
      final controller = PopupSelectController();
      await pumpBar(
        tester,
        controller,
        const [PopupTab(label: 'T0')],
        [
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a0', name: 'A0'),
            },
          ),
        ],
      );

      controller.toggleSelect(index: 0);
      await tester.pumpAndSettle();
      expect(controller.isSelectShowing, isTrue);

      controller.hideSelect();
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isFalse);
    });

    testWidgets('toggleSelect is a no-op for an out-of-range index', (
      tester,
    ) async {
      final controller = PopupSelectController();
      await pumpBar(
        tester,
        controller,
        const [PopupTab(label: 'T0')],
        [
          ListSelectDelegate(
            entriesLoader: () async => {
              SelectTextEntry<dynamic>(id: 'a0', name: 'A0'),
            },
          ),
        ],
      );

      // Index 5 is not registered; the controller must not open or throw.
      controller.toggleSelect(index: 5);
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isFalse);
      expect(controller.currentIndex, isNull);
    });
  });

  group('Selection restoration', () {
    test(
      'handleApply writes the applied selection back to delegate.selectedData',
      () {
        final delegate = ListSelectDelegate(
          entriesLoader: () async => <SelectEntry<dynamic>>{},
        );
        final controller = PopupSelectController();
        controller.attachSelectDelegates(<SelectDelegate>[delegate]);
        controller.currentIndex = 0;
        // Opening the selector sets `previousSelectDelegate`; `handleApply`
        // then writes the applied selection back onto it.
        controller.previousSelectDelegate = delegate;
        // `handleApply` writes the applied selection back to the active label
        // state, so a label state must exist at index 0.
        controller.labelStateMap[0] = SelectLabelState();

        final applied = _restorationEntries('a');
        controller.handleApply(applied, 'Selected');

        // The applied selection must be persisted on the delegate so that a
        // reopened controller (PopupSelectBar / Button / Dialog / bottom
        // sheet) reconstructs with `previousSelected = applied`.
        expect(delegate.selectedEntries, applied);
      },
    );

    testWidgets(
      'PopupSelectBar restores the previous selection when reopened',
      (tester) async {
        final controller = PopupSelectController();
        final delegate = ListSelectDelegate(
          selectionMode: SelectionMode.multiple,
          entriesLoader: () async => <SelectEntry<dynamic>>{
            SelectTextEntry<dynamic>(id: 'a', name: 'A'),
            SelectTextEntry<dynamic>(id: 'b', name: 'B'),
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: PopupSelectBar(
                tabs: const [PopupTab(label: 'Filter')],
                selectDelegates: [delegate],
                onApplied: (_, _) {},
                controller: controller,
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );

        // Open, select A, then press Apply (the action bar apply triggers
        // `handleApply`, which writes the selection back to `selectedData`).
        await tester.tap(find.widgetWithText(PopupTab, 'Filter'));
        await tester.pumpAndSettle();
        expect(controller.isSelectShowing, isTrue);
        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // The applied selection is written back to the delegate.
        expect(delegate.selectedEntries, isNotNull);
        expect(delegate.selectedEntries!.any((e) => e.id == 'a'), isTrue);

        // Reopen: the controller must be rebuilt with `selectedEntries` coming
        // from `delegate.selectedData`, so the previously applied selection is
        // restored rather than lost. The tab label now shows the applied value.
        await tester.tap(find.widgetWithText(PopupTab, 'A'));
        await tester.pumpAndSettle();

        expect(controller.isSelectShowing, isTrue);
        expect(controller.selectController, isNotNull);
        expect(
          controller.selectController!.selectedEntries!.any((e) => e.id == 'a'),
          isTrue,
        );
      },
    );
  });
}
