import 'dart:convert';

import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:genui/genui.dart';
import 'package:material_ui/material_ui.dart';

import 'llm_client.dart';

/// A chat page where a real model decides when to render a `Select`.
///
/// Flow: user text → model → A2UI JSON (fenced in the reply) →
/// [A2uiTransportAdapter] parses it → [SurfaceController] renders the
/// `Select` through the fl_select catalog → the user picks options → the page
/// sends the data model back to the model as the next user turn.
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
  _SurfaceEntry(this.surfaceId);
  final String surfaceId;
}

class _AgentPageState extends State<AgentPage> {
  late final Catalog _catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
    newItems: FlSelectCatalogItems.all,
  );
  late final SurfaceController _controller = SurfaceController(
    catalogs: [_catalog],
  );
  late final A2uiTransportAdapter _transport = A2uiTransportAdapter(
    onSend: _onSend,
  );
  late final Conversation _conversation = Conversation(
    controller: _controller,
    transport: _transport,
  );
  late final String _systemPrompt = PromptBuilder.chat(
    catalog: _catalog,
    systemPromptFragments: [
      PromptFragments.acknowledgeUser(),
      'Prefer a `Select` component whenever the user must choose from '
          'options. Keep the surface small: a Column with one short Text and '
          'one Select.',
      FlSelectCatalogItems.systemPromptFragment,
    ],
  ).systemPromptJoined();

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _entries = <_Entry>[];
  final _history = <LlmTurn>[];
  _TextEntry? _assistantBubble;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversation.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ConversationContentReceived(:final text):
          setState(() {
            final bubble = _assistantBubble ??= _TextEntry(
              fromUser: false,
              text: '',
            );
            if (!_entries.contains(bubble)) _entries.add(bubble);
            bubble.text += text;
          });
        case ConversationSurfaceAdded(:final surfaceId):
          setState(() => _entries.add(_SurfaceEntry(surfaceId)));
        case ConversationError(:final error):
          setState(() => _error = '$error');
        default:
      }
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onSend(ChatMessage message) async {
    _history.add((role: 'user', content: message.text));
    _assistantBubble = null;
    final reply = StringBuffer();
    await for (final chunk in widget.client.stream(
      systemPrompt: _systemPrompt,
      history: _history,
    )) {
      reply.write(chunk);
      _transport.addChunk(chunk);
    }
    _history.add((role: 'assistant', content: reply.toString()));
  }

  void _send(String text, {String? shown}) {
    if (text.trim().isEmpty) return;
    setState(() {
      _error = null;
      _entries.add(_TextEntry(fromUser: true, text: shown ?? text));
    });
    _conversation.sendRequest(ChatMessage.user(text));
    _scrollToEnd();
  }

  /// Reads everything the surface's `Select` wrote and sends it as the next
  /// user turn, so the model can react to the choice.
  void _submitSelection(String surfaceId) {
    final model = _controller.contextFor(surfaceId).dataModel;
    final values = model.getValue<Object?>(DataPath.root);
    final json = const JsonEncoder.withIndent('  ').convert(values);
    _send(
      'My selection (JSON from the data model):\n$json',
      shown: 'Submitted selection:\n$json',
    );
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
          ValueListenableBuilder<ConversationState>(
            valueListenable: _conversation.state,
            builder: (context, state, _) => state.isWaiting
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
              child: Text(entry.text.trim()),
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
                Surface(
                  surfaceContext: _controller.contextFor(entry.surfaceId),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => _submitSelection(entry.surfaceId),
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
