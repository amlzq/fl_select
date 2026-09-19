import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:fl_select_genui/src/catalog/fl_select_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

/// Pumps the `Select` catalog widget with [data] as the agent-supplied payload
/// and returns the DataContext so tests can inspect write-backs.
Future<DataContext> pumpSelect(
  WidgetTester tester,
  Map<String, Object?> data, {
  String id = 'select1',
}) async {
  final item = FlSelectCatalogItems.select;
  final model = InMemoryDataModel();
  final context = DataContext(model, DataPath('root'));
  await tester.pumpWidget(const MaterialApp(home: Placeholder()));
  final itemContext = CatalogItemContext(
    data: data,
    id: id,
    type: item.name,
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
    MaterialApp(home: Scaffold(body: item.widgetBuilder(itemContext))),
  );
  await tester.pumpAndSettle();
  return context;
}

/// The delegate the catalog wired into the [SelectView] on screen.
SelectDelegate delegateOf(WidgetTester tester) =>
    tester.widget<SelectView>(find.byType(SelectView)).delegate;

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

const _flatEntries = [
  {'type': 'text', 'id': 'recent', 'name': 'Recent'},
  {'type': 'text', 'id': 'cheapest', 'name': 'Cheapest'},
];

/// The delegate each documented `delegate` token must produce for a category
/// tree. Grouped tokens land on their own delegate; flat-only tokens fall
/// through to the grouped default.
final _categoryDelegates = <String, Matcher>{
  'list': isA<ExpandableSelectDelegate>(),
  'grid': isA<TabNavSelectDelegate>(),
  'wrap': isA<SideNavSelectDelegate>(),
  'cascading': isA<CascadingSelectDelegate>(),
  'tabNav': isA<TabNavSelectDelegate>(),
  'sideNav': isA<SideNavSelectDelegate>(),
  'expandable': isA<ExpandableSelectDelegate>(),
  'flatten': isA<SideNavSelectDelegate>(),
};

/// The same tokens for a flat option list: every grouped token falls back to
/// its flat equivalent, since only the flat-only delegates support flat data.
final _flatDelegates = <String, Matcher>{
  'list': isA<ListSelectDelegate>(),
  'grid': isA<GridSelectDelegate>(),
  'wrap': isA<WrapSelectDelegate>(),
  'cascading': isA<ListSelectDelegate>(),
  'tabNav': isA<ListSelectDelegate>(),
  'sideNav': isA<ListSelectDelegate>(),
  'expandable': isA<ListSelectDelegate>(),
  'flatten': isA<WrapSelectDelegate>(),
};

void main() {
  test('schema + exampleData + catalog merge', () {
    final item = FlSelectCatalogItems.select;
    expect(item.name, 'Select');
    expect(item.dataSchema.required, containsAll(['delegate', 'entries']));

    for (final example in item.exampleData) {
      final json = jsonDecode(example()) as Map<String, dynamic>;
      final entries = SelectEntryCodec.fromJson(json['entries'] as List);
      expect(entries.first, isA<SelectCategoryEntry>());
    }

    final merged = const Catalog(
      <CatalogItem>[],
      catalogId: 'base',
    ).copyWith(newItems: FlSelectCatalogItems.all);
    expect(merged.items.length, 1);
    expect(merged.items.map((item) => item.name), contains('Select'));
  });

  testWidgets('renders entries authored by an agent', (tester) async {
    await pumpSelect(tester, {'delegate': 'flatten', 'entries': _entries});

    expect(find.text('More'), findsWidgets);
    expect(find.text('A 1'), findsOneWidget);
    expect(find.text('A 2'), findsOneWidget);
  });

  testWidgets('writes the selection back to the data model', (tester) async {
    final context = await pumpSelect(tester, {
      'delegate': 'flatten',
      'selectionMode': 'single',
      'entries': _entries,
    });

    await tester.tap(find.text('A 2'));
    await tester.pumpAndSettle();

    final value =
        context.getValue<dynamic>(DataPath('select1.value'))
            as Map<dynamic, dynamic>;
    expect(value['more'], ['a2']);
  });

  testWidgets('flat entries write back under flatKey', (tester) async {
    final context = await pumpSelect(tester, {
      'delegate': 'list',
      'selectionMode': 'single',
      'flatKey': 'sort',
      'entries': _flatEntries,
    });

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    final value =
        context.getValue<dynamic>(DataPath('select1.value'))
            as Map<dynamic, dynamic>;
    expect(value['sort'], ['recent']);
  });

  testWidgets('flat entries without flatKey show an error card', (
    tester,
  ) async {
    await pumpSelect(tester, {'delegate': 'list', 'entries': _flatEntries});

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('shows an error card instead of crashing on bad entries', (
    tester,
  ) async {
    await pumpSelect(tester, {'delegate': 'flatten', 'entries': <Object?>[]});
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await pumpSelect(tester, {
      'delegate': 'flatten',
      'entries': [
        {'type': 'nonsense'},
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('delegate tokens map to the expected delegate', (tester) async {
    // Driven by the schema enum, so a newly documented token cannot ship
    // without an expected delegate (and a stale table entry cannot linger).
    final tokens = FlSelectCatalogItems
        .select
        .dataSchema
        .properties!['delegate']!
        .enumValues!
        .cast<String>();
    expect(tokens.toSet(), unorderedEquals(_categoryDelegates.keys));
    expect(_flatDelegates.keys, unorderedEquals(_categoryDelegates.keys));

    for (final token in tokens) {
      await pumpSelect(tester, {
        'delegate': token,
        'crossAxisCount': 2,
        'entries': _entries,
      });
      expect(
        delegateOf(tester),
        _categoryDelegates[token],
        reason: '"$token" with category entries',
      );

      await pumpSelect(tester, {
        'delegate': token,
        'crossAxisCount': 2,
        'flatKey': 'sort',
        'entries': _flatEntries,
      });
      expect(
        delegateOf(tester),
        _flatDelegates[token],
        reason: '"$token" with flat entries',
      );
    }
  });

  testWidgets('search flag toggles the search field', (tester) async {
    await pumpSelect(tester, {
      'delegate': 'flatten',
      'entries': _entries,
      'search': true,
    });
    expect(find.byType(TextField), findsOneWidget);

    await pumpSelect(tester, {'delegate': 'flatten', 'entries': _entries});
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('category layout is wired through', (tester) async {
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': [
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'layout': {'kind': 'grid', 'crossAxisCount': 2},
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
            {'type': 'text', 'id': 'b', 'name': 'B'},
            {'type': 'text', 'id': 'd', 'name': 'D'},
            {'type': 'text', 'id': 'e', 'name': 'E'},
          ],
        },
      ],
    });
    expect(find.byType(GridView), findsOneWidget);

    // A malformed layout shows the error card instead of crashing.
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': [
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'layout': {'kind': 'grid'},
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
          ],
        },
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('a custom range entry in a header/footer shows an error card', (
    tester,
  ) async {
    Map<String, Object?> payload({
      String row = 'header',
      bool nested = false,
    }) => {
      'delegate': 'sideNav',
      'entries': [
        {
          'type': 'category',
          'id': 'price',
          'name': 'Price',
          row: {
            'type': 'text',
            'id': 'h',
            'name': 'H',
            'children': [
              if (nested)
                {
                  'type': 'text',
                  'id': 'sub',
                  'name': 'Sub',
                  'children': [
                    {'type': 'custom', 'name': 'Custom'},
                  ],
                }
              else
                {'type': 'custom', 'name': 'Custom', 'min': 0, 'max': 1000},
            ],
          },
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
          ],
        },
      ],
    };

    // A chip row has no room for a custom range entry's input field, so the
    // payload is reported instead of letting the chip bar throw.
    await pumpSelect(tester, payload());
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await pumpSelect(tester, payload(row: 'footer'));
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Nested deeper than the chip row it is reported too, instead of being
    // silently dropped.
    await pumpSelect(tester, payload(nested: true));
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Under the category's own children a custom entry is supported.
    await pumpSelect(tester, {
      'delegate': 'sideNav',
      'entries': [
        {
          'type': 'category',
          'id': 'price',
          'name': 'Price',
          'header': {
            'type': 'text',
            'id': 'h',
            'name': 'H',
            'children': [
              {'type': 'any', 'name': 'Any'},
            ],
          },
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
            {'type': 'custom', 'name': 'Custom', 'min': 0, 'max': 1000},
          ],
        },
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('category header/footer are wired through', (tester) async {
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': [
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'header': {
            'type': 'text',
            'id': 'h',
            'name': 'H',
            'children': [
              {'type': 'any', 'name': 'Any'},
            ],
          },
          'footer': {
            'type': 'text',
            'id': 'f',
            'name': 'F',
            'children': [
              {'type': 'text', 'id': 'f1', 'name': 'Footer'},
            ],
          },
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
          ],
        },
      ],
    });
    expect(find.text('Any'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });
}
