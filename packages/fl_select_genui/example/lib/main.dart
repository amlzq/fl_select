import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:material_ui/material_ui.dart';

import 'agent_page.dart';
import 'llm_client.dart';

/// A payload exactly like one an AI agent would emit for `Select`
/// (see `FlSelectCatalogItems.systemPromptFragment`).
const agentPayload = '''
{
  "delegate": "sideNav",
  "selectionMode": "multiple",
  "entries": [
    {
      "type": "category",
      "id": "price",
      "name": "Price",
      "children": [
        {"type": "any", "name": "Any"},
        {"type": "range", "id": "0-100", "name": "\$0 - \$100", "min": 0, "max": 100},
        {"type": "range", "id": "100-300", "name": "\$100 - \$300", "min": 100, "max": 300},
        {"type": "custom", "name": "Custom", "min": 0, "max": 1000,
         "minHintText": "Min", "maxHintText": "Max"}
      ]
    },
    {
      "type": "category",
      "id": "amenities",
      "name": "Amenities",
      "children": [
        {"type": "text", "id": "wifi", "name": "Wi-Fi"},
        {"type": "text", "id": "parking", "name": "Parking"},
        {"type": "text", "id": "pool", "name": "Pool"}
      ]
    }
  ]
}
''';

// Provide these with `--dart-define`, e.g.
// flutter run --dart-define=LLM_API_KEY=sk-... --dart-define=LLM_MODEL=gpt-4o-mini
const _llmApiKey = String.fromEnvironment('LLM_API_KEY');
const _llmBaseUrl = String.fromEnvironment(
  'LLM_BASE_URL',
  defaultValue: 'https://api.openai.com/v1',
);
const _llmModel = String.fromEnvironment(
  'LLM_MODEL',
  defaultValue: 'gpt-4o-mini',
);

void main() {
  runApp(const FlSelectGenuiExample());
}

class FlSelectGenuiExample extends StatefulWidget {
  const FlSelectGenuiExample({super.key});

  @override
  State<FlSelectGenuiExample> createState() => _FlSelectGenuiExampleState();
}

class _FlSelectGenuiExampleState extends State<FlSelectGenuiExample> {
  /// Renders the payload as an app renders an agent's surface: as the root
  /// component of a surface on the fl_select catalog.
  final MessageProcessor<ComponentImplementation> _processor = MessageProcessor(
    catalogs: [FlSelectCatalogItems.asCatalog()],
    onError: (error) => debugPrint('${error.code}: ${error.message}'),
  );
  late final SurfaceModel<ComponentImplementation> _surface;

  /// The selection the Select writes to `<id>.value` relative to its data
  /// context, the surface root here. JSON Pointer separates segments with
  /// "/", so "root.value" is one key.
  late final DataSubscription<Object?> _selection;

  @override
  void initState() {
    super.initState();
    _processor.processMessages([
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'example-surface',
          'catalogId': 'fl_select',
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'example-surface',
          'components': [
            {
              'id': 'root',
              'component': 'Select',
              ...jsonDecode(agentPayload) as Map<String, Object?>,
            },
          ],
        },
      },
    ]);
    _surface = _processor.model.getSurface('example-surface')!;
    _selection = _surface.dataModel.subscribe<Object?>(
      '/root.value',
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _selection.unsubscribe();
    _processor.dispose();
    super.dispose();
  }

  void _openAgent(BuildContext context) {
    if (_llmApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Run with --dart-define=LLM_API_KEY=<your key>'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgentPage(
          client: ChatCompletionsClient(
            apiKey: _llmApiKey,
            baseUrl: _llmBaseUrl,
            model: _llmModel,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('fl_select_genui example'),
          actions: [
            Builder(
              builder: (context) => TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Agent chat'),
                onPressed: () => _openAgent(context),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: '1. Agent payload (AI-generated JSON)',
              child: Text(
                agentPayload,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            _Section(
              title: '2. Rendered Select',
              child: A2uiSurface(surface: _surface),
            ),
            _Section(
              title: '3. Selection written back to the data model',
              child: SelectableText(
                _selection.value == null
                    ? '(nothing selected yet — tap an option above)'
                    : const JsonEncoder.withIndent('  ')
                          .convert(_selection.value),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
