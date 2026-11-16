import 'dart:convert';

import 'package:a2ui_flutter/basic_catalog.dart';
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
    yield 'Sure, pick one.\n<a2ui-json>\n[$create, $update]\n</a2ui-json>\n';
  }
}

/// Replies like a model that writes Markdown in a surface's `Text`.
class _MarkdownLlm implements LlmClient {
  @override
  Stream<String> stream({
    required String systemPrompt,
    required List<LlmTurn> history,
  }) async* {
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
            'component': 'Column',
            'children': ['text', 'select'],
          },
          {
            'id': 'text',
            'component': 'Text',
            'text': 'Pick **bold** or plain.',
          },
          {
            'id': 'select',
            'component': 'Select',
            'delegate': 'list',
            'selectionMode': 'single',
            'flatKey': 'sort',
            'entries': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
              {'type': 'text', 'id': 'b', 'name': 'B'},
            ],
          },
        ],
      },
    });
    yield '<a2ui-json>\n[$create, $update]\n</a2ui-json>\n';
  }
}

/// Whether [span] has a bold descendant whose text contains [text].
bool _hasBoldSpan(InlineSpan span, String text) {
  if (span is! TextSpan) return false;
  if ((span.text ?? '').contains(text) &&
      span.style?.fontWeight == FontWeight.bold) {
    return true;
  }
  return span.children?.any((child) => _hasBoldSpan(child, text)) ?? false;
}

/// Replies with a surface that keeps the same id every turn, which the
/// renderer rejects once the first turn has created it.
class _ReusingLlm implements LlmClient {
  @override
  Stream<String> stream({
    required String systemPrompt,
    required List<LlmTurn> history,
  }) async* {
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
              {'type': 'text', 'id': 'a', 'name': 'A'},
              {'type': 'text', 'id': 'b', 'name': 'B'},
            ],
          },
        ],
      },
    });
    yield '<a2ui-json>\n[$create, $update]\n</a2ui-json>\n';
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
    // Replies render as Markdown, so the text lives in a RichText.
    expect(find.text('Thanks, noted.', findRichText: true), findsOneWidget);
  });

  testWidgets('renders a surface Text body as Markdown', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AgentPage(client: _MarkdownLlm())),
    );
    await tester.enterText(find.byType(TextField), 'pick something');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectView), findsOneWidget);

    // "**bold**" becomes a bold span instead of literal asterisks.
    final richTexts = tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(A2uiMarkdown),
        matching: find.byType(RichText),
      ),
    );
    expect(
      richTexts.any((richText) => _hasBoldSpan(richText.text, 'bold')),
      isTrue,
    );
  });

  testWidgets('surfaces a renderer error instead of dropping it silently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AgentPage(client: _ReusingLlm())),
    );

    await tester.enterText(find.byType(TextField), 'first');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-error')), findsNothing);

    // The second turn creates surface "s1" again, which the renderer rejects.
    await tester.enterText(find.byType(TextField), 'second');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-error')), findsOneWidget);
  });
}
