import 'dart:async';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  ) bodyBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected, {
    String searchQuery = '',
  }) =>
      bodyBuilder(context, entries, previousSelected);

  @override
  Widget buildSkeleton(BuildContext context) =>
      skeletonBuilder?.call(context) ?? const Text('skeleton');
}

void main() {
  group('SelectPanel', () {
    testWidgets('shows the skeleton while data is loading', (tester) async {
      final completer = Completer<SelectEntries>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () => completer.future,
                bodyBuilder: (_, __, ___) => const Text('body'),
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
                bodyBuilder: (_, __, ___) => const Text('body'),
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
        'shows an error when a 2D structure has a mismatched parentId instead of hanging',
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
                bodyBuilder: (_, __, ___) => const Text('body'),
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
    });

    testWidgets(
        'uses errorBuilder for a 2D structure with a mismatched parentId',
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
                bodyBuilder: (_, __, ___) => const Text('body'),
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
    });

    testWidgets('uses errorBuilder when data fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => throw Exception('boom'),
                bodyBuilder: (_, __, ___) => const Text('body'),
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

    testWidgets('forwards callbacks with an external controller',
        (tester) async {
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
                bodyBuilder: (_, __, ___) => const SizedBox(),
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

    testWidgets('forwards callbacks with an internal controller',
        (tester) async {
      SelectController? captured;
      var changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (context, _, __) {
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

    testWidgets('does not dispose an externally-provided controller',
        (tester) async {
      final controller = SelectController(selectionMode: SelectionMode.single);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectPanel(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, __, ___) => const SizedBox(),
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
                bodyBuilder: (context, _, __) {
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

    testWidgets('re-registers forwarding listeners when controller changes',
        (tester) async {
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
                bodyBuilder: (_, __, ___) => const SizedBox(),
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
                bodyBuilder: (_, __, ___) => const SizedBox(),
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

    testWidgets('initializes the internal controller from delegate state',
        (tester) async {
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
                bodyBuilder: (context, _, __) {
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
}
