import 'package:fl_select_genui/src/catalog/fl_select_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

/// Pumps the SelectFilter catalog widget with [data] as the agent-supplied
/// payload and returns the DataContext so tests can inspect write-backs.
Future<DataContext> pumpFilter(
  WidgetTester tester,
  Map<String, Object?> data, {
  String id = 'filter1',
}) async {
  final model = InMemoryDataModel();
  final context = DataContext(model, DataPath('root'));
  await tester.pumpWidget(const MaterialApp(home: Placeholder()));
  final itemContext = CatalogItemContext(
    data: data,
    id: id,
    type: 'SelectFilter',
    buildChild: (_, [_]) => const SizedBox.shrink(),
    dispatchEvent: (_) {},
    buildContext: tester.element(find.byType(Placeholder)),
    dataContext: context,
    getComponent: (_) => null,
    getCatalogItem: (_) => null,
    surfaceId: 'test-surface',
    reportError: (_, _) {},
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FlSelectCatalogItems.selectFilter.widgetBuilder(itemContext),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return context;
}

const _entries = [
  {
    'type': 'category',
    'id': 'more',
    'name': 'More',
    'children': [
      {'type': 'text', 'id': 'a1', 'name': 'A 1'},
      {'type': 'text', 'id': 'a2', 'name': 'A 2'},
    ],
  },
];

void main() {
  testWidgets('renders entries authored by an agent', (tester) async {
    await pumpFilter(tester, {'delegate': 'flatten', 'entries': _entries});

    expect(find.text('More'), findsWidgets);
    expect(find.text('A 1'), findsOneWidget);
    expect(find.text('A 2'), findsOneWidget);
  });

  testWidgets('writes the selection back to the data model', (tester) async {
    final context = await pumpFilter(tester, {
      'delegate': 'flatten',
      'selectionMode': 'single',
      'entries': _entries,
    });

    await tester.tap(find.text('A 2'));
    await tester.pumpAndSettle();

    final value =
        context.getValue<dynamic>(DataPath('filter1.value'))
            as Map<dynamic, dynamic>;
    expect(value['more'], ['a2']);
  });

  testWidgets('shows an error card instead of crashing on bad entries', (
    tester,
  ) async {
    await pumpFilter(tester, {'delegate': 'flatten', 'entries': <Object?>[]});
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await pumpFilter(tester, {
      'delegate': 'flatten',
      'entries': [
        {'type': 'nonsense'},
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('all delegate tokens build without throwing', (tester) async {
    for (final delegate in [
      'list',
      'grid',
      'wrap',
      'cascading',
      'tabNav',
      'sideNav',
      'expandable',
      'flatten',
    ]) {
      await pumpFilter(tester, {
        'delegate': delegate,
        'crossAxisCount': 2,
        'entries': _entries,
      });
      expect(
        find.byIcon(Icons.warning_amber_rounded),
        findsNothing,
        reason: '$delegate delegate should render',
      );
    }
  });
}
