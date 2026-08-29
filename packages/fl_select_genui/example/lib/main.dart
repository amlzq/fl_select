import 'dart:convert';

import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// A payload exactly like one an AI agent would emit for `SelectFilter`
/// (see [FlSelectCatalogItems.systemPromptFragment]).
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

void main() {
  runApp(const FlSelectGenuiDemo());
}

class FlSelectGenuiDemo extends StatefulWidget {
  const FlSelectGenuiDemo({super.key});

  @override
  State<FlSelectGenuiDemo> createState() => _FlSelectGenuiDemoState();
}

class _FlSelectGenuiDemoState extends State<FlSelectGenuiDemo> {
  final DataModel _model = InMemoryDataModel();
  late final DataContext _dataContext = DataContext(_model, DataPath('root'));

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('fl_select_genui demo')),
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
              title: '2. Rendered SelectFilter',
              child: Builder(
                builder: (buildContext) {
                  final item = FlSelectCatalogItems.selectFilter;
                  return item.widgetBuilder(
                    CatalogItemContext(
                      data: jsonDecode(agentPayload) as JsonMap,
                      id: 'demo',
                      type: item.name,
                      buildChild: (_, [_]) => const SizedBox.shrink(),
                      dispatchEvent: (_) {},
                      buildContext: buildContext,
                      dataContext: _dataContext,
                      getComponent: (_) => null,
                      getCatalogItem: (_) => null,
                      surfaceId: 'demo-surface',
                      reportError: (error, _) => debugPrint('$error'),
                    ),
                  );
                },
              ),
            ),
            _Section(
              title: '3. Selection written back to the data model',
              child: ValueListenableBuilder(
                valueListenable: _model.subscribe<dynamic>(
                  DataPath('root.demo.value'),
                ),
                builder: (context, value, _) => SelectableText(
                  value == null
                      ? '(nothing selected yet — tap a filter above)'
                      : const JsonEncoder.withIndent('  ').convert(value),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
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
