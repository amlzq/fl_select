import 'dart:async';
import 'dart:convert';

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;
import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:material_ui/material_ui.dart';

import 'llm_client.dart';

/// A chat page where a real model decides when to render a `Select`.
///
/// Flow: user text → model → A2UI JSON (in `<a2ui-json>` blocks of the reply)
/// → an a2ui_agent response stream parses it → a [MessageProcessor] renders
/// the `Select` through the fl_select catalog → the user picks options → the
/// page sends the data model back to the model as the next user turn.
class AgentPage extends StatefulWidget {
  const AgentPage({super.key, required this.client});

  final LlmClient client;

  @override
  State<AgentPage> createState() => _AgentPageState();
}

sealed class _Entry {}

class _TextEntry extends _Entry {
  _TextEntry({required this.fromUser, required this.text});
  final bool fromUser;
  String text;
}

class _SurfaceEntry extends _Entry {
  _SurfaceEntry(this.surface);
  final SurfaceModel<ComponentImplementation> surface;
}

class _AgentPageState extends State<AgentPage> {
  /// The basic catalog without its media components, plus the fl_select ones.
  late final CatalogImplementation _catalog = v0_9.basicCatalog().copyWith(
    components: [
      for (final component in v0_9.BasicComponents.all)
        if (!const {'Image', 'Video', 'AudioPlayer'}.contains(component.name))
          component,
      ...FlSelectCatalogItems.all,
    ],
  );
  late final MessageProcessor<ComponentImplementation> _processor =
      MessageProcessor(
        catalogs: [_catalog],
        // A surface streams in over several messages, which the strict checks
        // would reject.
        validationConfig: ValidationConfig.relaxed,
        reportErrorsOnly: true,
      );
  late final A2uiRequestProcessor _agent =
      A2uiGenerator(
        catalogs: [CatalogConfig(_catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(
          // Each turn creates new surfaces and fills them in.
          allowedMessages: ['createSurface', 'updateComponents'],
          // Hand the renderer whole components, not half-streamed ones.
          bufferIncompleteComponents: true,
        ),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([
          _catalog.id,
        ], version: A2uiProtocolVersion.v0_9),
      );
  late final String _systemPrompt = [
    'Your responses should contain acknowledgment of the user message.',
    'Prefer a `Select` component whenever the user must choose from '
        'options. Keep the surface small: a Column with one short Text and '
        'one Select. Never use a Row; stack everything in a Column so nothing '
        'overflows a phone screen. Put all user-facing wording inside the surface\'s Text; '
        'do not repeat it as plain text outside the surface.',
    FlSelectCatalogItems.systemPromptFragment,
    // genui's chat prompt kept every turn to surfaces of its own.
    'IMPORTANT: DO NOT update or modify surfaces created in previous turns. '
        'If the UI needs to change, you MUST create a NEW surface with a new '
        'unique `surfaceId`. You may only use `updateComponents` to populate '
        'the components of a freshly created surface.',
    _agent.promptSnippet,
  ].join('\n\n');
  late final List<Subscription> _subscriptions;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _entries = <_Entry>[];
  final _history = <LlmTurn>[];
  final _waiting = ValueNotifier<bool>(false);
  _TextEntry? _assistantBubble;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      _processor.model.onSurfaceCreated.subscribe((surface) {
        if (!mounted) return;
        setState(() => _entries.add(_SurfaceEntry(surface)));
        _scrollToEnd();
      }),
      // Messages the renderer rejects, and errors its surfaces meet.
      _processor.model.onError.subscribe(
        (error) => debugPrint('${error.code}: ${error.message}'),
      ),
    ];
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _processor.dispose();
    _waiting.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onSend(String text) async {
    _history.add((role: 'user', content: text));
    _assistantBubble = null;
    final reply = StringBuffer();
    // No renderer state: each reply is checked on its own, as a chat turn.
    final ContinuingResponseStream parts = _agent.openContinuingStream();
    await for (final chunk in widget.client.stream(
      systemPrompt: _systemPrompt,
      history: _history,
    )) {
      reply.write(chunk);
      _deliver(parts.feed(chunk));
    }
    _deliver(parts.close());
    _history.add((role: 'assistant', content: reply.toString()));
  }

  /// Shows the text and renders the A2UI messages of a reply as they stream.
  void _deliver(List<StreamPart> parts) {
    if (!mounted) return;
    for (final part in parts) {
      switch (part) {
        case TextPart(:final text):
          setState(() {
            final bubble = _assistantBubble ??= _TextEntry(
              fromUser: false,
              text: '',
            );
            if (!_entries.contains(bubble)) _entries.add(bubble);
            bubble.text += text;
          });
          _scrollToEnd();
        case A2uiPart(:final a2ui):
          _processor.processMessages(AgentToRendererMessagePayload(a2ui));
        case ErrorPart(:final error):
          // A block the stream rejected; the rest of the reply still renders.
          debugPrint('$error');
      }
    }
  }

  void _send(String text, {String? shown}) {
    if (text.trim().isEmpty) return;
    setState(() {
      _error = null;
      _entries.add(_TextEntry(fromUser: true, text: shown ?? text));
    });
    unawaited(_request(text));
    _scrollToEnd();
  }

  /// Runs one model turn for [text] and shows a failed request as the error.
  Future<void> _request(String text) async {
    _waiting.value = true;
    try {
      await _onSend(text);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
      _scrollToEnd();
    } finally {
      if (mounted) _waiting.value = false;
    }
  }

  /// Reads everything the surface's `Select` wrote and sends it as the next
  /// user turn, so the model can react to the choice.
  void _submitSelection(SurfaceModel<ComponentImplementation> surface) {
    final values = surface.dataModel.get('/');
    final json = const JsonEncoder.withIndent('  ').convert(values);
    _send(
      'My selection (JSON from the data model):\n$json',
      shown: _describe(values),
    );
  }

  /// Human-readable echo of the data model, e.g. `hotel: grand-plaza`.
  String _describe(Object? values) {
    if (values is! Map) return 'Selection submitted';
    final parts = <String>[];
    void walk(String prefix, Object? v) {
      if (v is Map) {
        v.forEach(
          (k, child) => walk(prefix.isEmpty ? '$k' : '$prefix.$k', child),
        );
      } else if (v is Iterable) {
        parts.add('$prefix: ${v.join(', ')}');
      } else if (v != null) {
        parts.add('$prefix: $v');
      }
    }

    walk('', values);
    return parts.isEmpty ? 'Selection submitted' : parts.join('\n');
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              children: [
                if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Try: "Help me pick a hotel", or "I want to sort the '
                      'results".',
                    ),
                  ),
                for (final entry in _entries) _buildEntry(entry),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _waiting,
            builder: (context, waiting, _) => waiting
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Message the agent',
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _submit(_input.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String text) {
    _input.clear();
    _send(text);
  }

  Widget _buildEntry(_Entry entry) {
    switch (entry) {
      case _TextEntry():
        return Align(
          alignment: entry.fromUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Card(
            color: entry.fromUser
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                entry.text.trim().replaceAll(RegExp(r'\n\s*\n+'), '\n\n'),
              ),
            ),
          ),
        );
      case _SurfaceEntry():
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                A2uiSurface(
                  key: ObjectKey(entry.surface),
                  surface: entry.surface,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => _submitSelection(entry.surface),
                    child: const Text('Send selection'),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
