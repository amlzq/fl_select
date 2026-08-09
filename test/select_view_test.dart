import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal [SelectDelegate] used to drive [SelectView] rendering and
/// to capture the active controller for assertions.
class _TestDelegate extends SelectDelegate {
  _TestDelegate({
    required this.bodyBuilder,
    required super.entriesLoader,
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
    Set<SelectEntry>? previousSelected,
  ) =>
      bodyBuilder(context, entries, previousSelected);

  @override
  Widget buildSkeleton(BuildContext context) => const Text('skeleton');
}

void main() {
  group('SelectView', () {
    testWidgets('renders the body once data is available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                },
                bodyBuilder: (context, entries, _) =>
                    Text('entries:${entries.length}'),
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('entries:1'), findsOneWidget);
    });

    testWidgets('forwards onChanged through an internal controller',
        (tester) async {
      SelectController? captured;
      var changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (context, _, __) {
                  captured = SelectController.of(context);
                  return const SizedBox();
                },
              ),
              onChanged: (_) => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      captured!.change(<SelectEntry>{});

      expect(changed, isTrue);
    });

    testWidgets('disposes its own internal controller on unmount',
        (tester) async {
      SelectController? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (context, _, __) {
                  captured = SelectController.of(context);
                  return const SizedBox();
                },
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(captured!.isDisposed, isTrue);
    });

    testWidgets('does not dispose an externally-provided controller',
        (tester) async {
      final controller = SelectController(selectionMode: SelectionMode.single);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: _TestDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{},
                bodyBuilder: (_, __, ___) => const SizedBox(),
              ),
              controller: controller,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.isDisposed, isFalse);
    });

    testWidgets('caps height to maxHeightFactor of the screen height',
        (tester) async {
      const mediaQuery = MediaQueryData(size: Size(400, 800));
      await tester.pumpWidget(
        MediaQuery(
          data: mediaQuery,
          child: MaterialApp(
            home: Scaffold(
              body: SelectView(
                maxHeightFactor: 0.5,
                delegate: _TestDelegate(
                  entriesLoader: () async => <SelectEntry<dynamic>>{},
                  // A tall, unconstrained body to verify the cap is applied.
                  bodyBuilder: (_, __, ___) => Container(height: 5000.0),
                ),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The internal ConstrainedBox must cap the height at the expected factor.
      final hasCap = tester
          .widgetList(find.byType(ConstrainedBox))
          .where((w) => w is ConstrainedBox && w.constraints.maxHeight == 400)
          .isNotEmpty;
      expect(hasCap, isTrue);
    });
  });
}
