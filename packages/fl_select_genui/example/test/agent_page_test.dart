import 'dart:convert';

import 'package:example/agent_page.dart';
import 'package:example/llm_client.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _catalogId =
    'https://a2ui.org/specification/v0_9/catalogs/basic/catalog.json';

/// Replies like a model that answers with one `Select` surface, and records
/// what it was sent so the test can check the selection round trip.
class _FakeLlm implements LlmClient {
  final received = <List<LlmTurn>>[];
  String? systemPrompt;

  @override
  Stream<String> stream({
    required String systemPrompt,
    required List<LlmTurn> history,
  }) async* {
    this.systemPrompt = systemPrompt;
    received.add(List.of(history));
    if (received.length > 1) {
      yield 'Thanks, noted.';
      return;
    }
    final create = jsonEncode({
      'version': 'v0.9',
      'createSurface': {'surfaceId': 's1', 'catalogId': _catalogId},
    });
    final update = jsonEncode({
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 's1',
        'components': [
          {
            'id': 'root',
            'component': 'Select',
            'delegate': 'list',
            'selectionMode': 'single',
            'flatKey': 'sort',
            'entries': [
              {'type': 'text', 'id': 'recent', 'name': 'Most recent'},
              {'type': 'text', 'id': 'cheapest', 'name': 'Cheapest'},
            ],
          },
        ],
      },
    });
    yield 'Sure, pick one.\n```json\n$create\n```\n```json\n$update\n```\n';
  }
}

void main() {
  testWidgets('agent reply renders a Select and the selection goes back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final llm = _FakeLlm();
    await tester.pumpWidget(MaterialApp(home: AgentPage(client: llm)));

    await tester.enterText(find.byType(TextField), 'sort the results');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(llm.systemPrompt, contains('Select'));
    expect(find.byType(SelectView), findsOneWidget);
    expect(find.text('Cheapest'), findsOneWidget);

    await tester.tap(find.text('Cheapest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send selection'));
    await tester.pumpAndSettle();

    expect(llm.received, hasLength(2));
    final last = llm.received.last.last;
    expect(last.role, 'user');
    expect(last.content, contains('cheapest'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Thanks, noted.'), findsOneWidget);
  });
}
