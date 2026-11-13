import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;
import 'package:fl_select/fl_select.dart';
import 'package:fl_select_genui/src/catalog/fl_select_catalog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// What [pumpSelect] rendered: the surface's data model, which the `Select`
/// writes its selection to, and the errors the processor reported.
typedef SelectHarness = ({DataModel dataModel, List<A2uiRendererError> errors});

/// Renders [components] on a v0.9 surface of [catalog], with the processor
/// checks that tests of a component use.
Future<SelectHarness> pumpSurface(
  WidgetTester tester,
  List<Map<String, Object?>> components, {
  CatalogImplementation? catalog,
}) async {
  final catalogImpl = catalog ?? FlSelectCatalogItems.asCatalog();
  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: [catalogImpl],
    validationConfig: ValidationConfig.strict,
    reportErrorsOnly: true,
  );
  addTearDown(processor.dispose);
  final errors = <A2uiRendererError>[];
  processor.model.onError.subscribe(errors.add);
  processor.processMessages([
    {
      'version': 'v0.9',
      'createSurface': {'surfaceId': 's', 'catalogId': catalogImpl.id},
    },
    {
      'version': 'v0.9',
      'updateComponents': {'surfaceId': 's', 'components': components},
    },
  ]);
  final surface = processor.model.getSurface('s')!;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: A2uiSurface(surface: surface)),
    ),
  );
  await tester.pumpAndSettle();
  return (dataModel: surface.dataModel, errors: errors);
}

/// Pumps the `Select` catalog component, as the surface root, with [data] as
/// the agent-supplied payload.
Future<SelectHarness> pumpSelect(
  WidgetTester tester,
  Map<String, Object?> data,
) => pumpSurface(tester, [
  {'id': 'root', 'component': 'Select', ...data},
]);

/// The selection the root `Select` wrote back to the data model.
Map<dynamic, dynamic> selectionOf(SelectHarness harness) =>
    harness.dataModel.get('/root.value') as Map<dynamic, dynamic>;

/// Checks that the processor rejected the payload because its [property] does
/// not match the `Select` schema, so nothing rendered.
void expectRejected(SelectHarness harness, String property) {
  expect(find.byType(SelectView), findsNothing);
  expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  expect(harness.errors, hasLength(1));
  expect(harness.errors.single.code, 'VALIDATION_FAILED');
  expect(harness.errors.single.path, startsWith('/components/0/$property'));
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
};

void main() {
  test('schema + catalog merge', () {
    final item = FlSelectCatalogItems.select;
    expect(item.name, 'Select');
    expect(
      (item.schema as ObjectSchema).required,
      containsAll(['delegate', 'entries']),
    );

    final merged = CatalogImplementation(
      id: 'base',
      components: const [],
    ).derive(catalogId: 'base', addComponents: FlSelectCatalogItems.all);
    expect(merged.components.length, 1);
    expect(merged.components.keys, contains('Select'));

    final catalog = FlSelectCatalogItems.asCatalog();
    expect(catalog.id, 'fl_select');
    expect(catalog.components.keys, ['Select']);
  });

  testWidgets('renders entries authored by an agent', (tester) async {
    final harness = await pumpSelect(tester, {
      'delegate': 'sideNav',
      'entries': _entries,
    });

    expect(harness.errors, isEmpty);
    expect(find.text('More'), findsWidgets);
    expect(find.text('A 1'), findsOneWidget);
    expect(find.text('A 2'), findsOneWidget);
  });

  testWidgets('renders a payload with every entry type', (tester) async {
    // The payload genui's `exampleData` carried for this component.
    final harness = await pumpSelect(tester, {
      'delegate': 'sideNav',
      'selectionMode': 'multiple',
      'entries': [
        {
          'type': 'category',
          'id': 'price',
          'name': 'Price',
          'children': [
            {'type': 'any', 'name': 'Any'},
            {
              'type': 'range',
              'id': '0-100',
              'name': r'$0 - $100',
              'min': 0,
              'max': 100,
            },
            {
              'type': 'range',
              'id': '100-300',
              'name': r'$100 - $300',
              'min': 100,
              'max': 300,
            },
            {'type': 'custom', 'name': 'Custom', 'min': 0, 'max': 1000},
          ],
        },
        {
          'type': 'category',
          'id': 'amenities',
          'name': 'Amenities',
          'children': [
            {'type': 'text', 'id': 'wifi', 'name': 'Wi-Fi'},
            {'type': 'text', 'id': 'parking', 'name': 'Parking'},
            {'type': 'text', 'id': 'pool', 'name': 'Pool'},
          ],
        },
      ],
    });

    expect(harness.errors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.byType(SelectView), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('writes the selection back to the data model', (tester) async {
    final harness = await pumpSelect(tester, {
      'delegate': 'sideNav',
      'selectionMode': 'single',
      'entries': _entries,
    });

    await tester.tap(find.text('A 2'));
    await tester.pumpAndSettle();

    expect(selectionOf(harness)['more'], ['a2']);
  });

  testWidgets('writes the selection back under its own component id', (
    tester,
  ) async {
    // Inside a container, as an agent lays out a surface, the selection lands
    // at `<id>.value` of the Select itself, not of the surface root.
    final catalog = v0_9.basicCatalog().copyWith(
      components: [v0_9.BasicComponents.column, ...FlSelectCatalogItems.all],
    );
    final harness = await pumpSurface(tester, catalog: catalog, [
      {
        'id': 'root',
        'component': 'Column',
        'children': ['select1', 'bad~id'],
      },
      {
        'id': 'select1',
        'component': 'Select',
        'delegate': 'list',
        'selectionMode': 'single',
        'flatKey': 'sort',
        'entries': _flatEntries,
      },
      {
        'id': 'bad~id',
        'component': 'Select',
        'delegate': 'wrap',
        'flatKey': 'size',
        'entries': [
          {'type': 'text', 'id': 'small', 'name': 'Small'},
        ],
      },
    ]);
    expect(harness.errors, isEmpty);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    expect(harness.dataModel.get('/select1.value'), {
      'sort': ['recent'],
    });

    // An id that is not a valid JSON Pointer segment cannot be written to;
    // the failure is reported instead of thrown.
    await tester.tap(find.text('Small'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(harness.errors.single.code, 'DATA_ERROR');
  });

  testWidgets('flat entries write back under flatKey', (tester) async {
    final harness = await pumpSelect(tester, {
      'delegate': 'list',
      'selectionMode': 'single',
      'flatKey': 'sort',
      'entries': _flatEntries,
    });

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    expect(selectionOf(harness)['sort'], ['recent']);
  });

  testWidgets('flat multiple selection accumulates under flatKey and clears', (
    tester,
  ) async {
    final harness = await pumpSelect(tester, {
      'delegate': 'list',
      'selectionMode': 'multiple',
      'flatKey': 'sort',
      'entries': _flatEntries,
    });
    Map<dynamic, dynamic> value() => selectionOf(harness);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cheapest'));
    await tester.pumpAndSettle();
    expect(value()['sort'], unorderedEquals(['recent', 'cheapest']));

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    expect(value()['sort'], ['cheapest']);

    // Deselecting the last option writes an empty map, not a stale value.
    await tester.tap(find.text('Cheapest'));
    await tester.pumpAndSettle();
    expect(value(), isEmpty);
  });

  testWidgets('flat entries without flatKey show an error card', (
    tester,
  ) async {
    await pumpSelect(tester, {'delegate': 'list', 'entries': _flatEntries});

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('rejects entries that do not match the schema', (tester) async {
    // The processor checks the payload against the component schema before it
    // renders, so these never reach the error card.
    var harness = await pumpSelect(tester, {
      'delegate': 'list',
      'entries': <Object?>[],
    });
    expectRejected(harness, 'entries');

    harness = await pumpSelect(tester, {
      'delegate': 'sideNav',
      'entries': [
        {'type': 'nonsense'},
      ],
    });
    expectRejected(harness, 'entries/0/type');
  });

  testWidgets('duplicate sibling ids show an error card', (tester) async {
    // fl_select 0.15.0 rejects duplicate sibling ids when the panel binds the
    // tree; the catalog reports the payload through its own error card instead
    // of letting the panel raise a FlutterError mid-build.
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': [
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'children': [
            {'type': 'text', 'id': 'dup', 'name': 'A'},
            {'type': 'range', 'id': 'dup', 'name': 'B', 'min': 0, 'max': 10},
          ],
        },
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // A category's header/footer is a sibling scope of its own.
    await pumpSelect(tester, {
      'delegate': 'sideNav',
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
              {'type': 'text', 'id': 'dup', 'name': 'A'},
              {'type': 'range', 'id': 'dup', 'name': 'B', 'min': 0, 'max': 10},
            ],
          },
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
          ],
        },
      ],
    });
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('delegate tokens map to the expected delegate', (tester) async {
    // Driven by the schema enum, so a newly documented token cannot ship
    // without an expected delegate (and a stale table entry cannot linger).
    final tokens = (FlSelectCatalogItems.select.schema as ObjectSchema)
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

  testWidgets('defaultLayout and isScrollable reach the delegates', (
    tester,
  ) async {
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'isScrollable': true,
      'defaultLayout': {'kind': 'grid', 'crossAxisCount': 2},
      'entries': _entries,
    });
    var tabNav = delegateOf(tester) as TabNavSelectDelegate;
    expect(tabNav.isScrollable, isTrue);
    expect(
      tabNav.defaultLayout,
      isA<SelectGridLayout>().having((l) => l.crossAxisCount, 'cols', 2),
    );

    await pumpSelect(tester, {
      'delegate': 'expandable',
      'defaultLayout': {'kind': 'chip'},
      'entries': _entries,
    });
    expect(
      (delegateOf(tester) as ExpandableSelectDelegate).defaultLayout,
      isA<SelectWrapLayout>(),
    );

    // Omitted: tabNav keeps its default, sideNav keeps scrolling.
    await pumpSelect(tester, {'delegate': 'tabNav', 'entries': _entries});
    tabNav = delegateOf(tester) as TabNavSelectDelegate;
    expect(tabNav.isScrollable, isFalse);
    expect(tabNav.defaultLayout, isNull);
    await pumpSelect(tester, {'delegate': 'sideNav', 'entries': _entries});
    expect((delegateOf(tester) as SideNavSelectDelegate).isScrollable, isTrue);

    await pumpSelect(tester, {
      'delegate': 'cascading',
      'isScrollable': true,
      'entries': _entries,
    });
    expect(
      (delegateOf(tester) as CascadingSelectDelegate).isScrollable,
      isTrue,
    );
  });

  testWidgets('a bad defaultLayout shows the schema error card', (
    tester,
  ) async {
    // Not an object at all: the processor rejects it against the schema.
    final harness = await pumpSelect(tester, {
      'delegate': 'tabNav',
      'defaultLayout': 'chip',
      'entries': _entries,
    });
    expectRejected(harness, 'defaultLayout');

    for (final bad in <Object?>[
      {'kind': 'bogus'},
      {'x': 1},
    ]) {
      await pumpSelect(tester, {
        'delegate': 'tabNav',
        'defaultLayout': bad,
        'entries': _entries,
      });
      expect(tester.takeException(), isNull, reason: '$bad');
      expect(find.textContaining('Invalid defaultLayout'), findsOneWidget);
    }
  });

  testWidgets('tabNav scrolls only when its labels do not fit', (tester) async {
    List<Map<String, Object?>> categories(int count, String prefix) => [
      for (var i = 0; i < count; i++)
        {
          'type': 'category',
          'id': 'c$i',
          'name': '$prefix $i',
          'children': [
            {'type': 'text', 'id': 't$i', 'name': 'Option $i'},
          ],
        },
    ];
    bool scrolls(TabNavSelectDelegate d) => d.isScrollable;

    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': categories(3, 'Tab'),
    });
    expect(scrolls(delegateOf(tester) as TabNavSelectDelegate), isFalse);

    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': categories(12, 'Category'),
    });
    expect(scrolls(delegateOf(tester) as TabNavSelectDelegate), isTrue);

    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': categories(3, 'A very long category name indeed'),
    });
    expect(scrolls(delegateOf(tester) as TabNavSelectDelegate), isTrue);

    // An explicit value always wins over the heuristic.
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'isScrollable': false,
      'entries': categories(12, 'Category'),
    });
    expect(scrolls(delegateOf(tester) as TabNavSelectDelegate), isFalse);
  });

  testWidgets('malformed crossAxisCount falls back instead of throwing', (
    tester,
  ) async {
    for (final bad in <Object?>[0, -2, 4.0]) {
      await pumpSelect(tester, {
        'delegate': 'grid',
        'crossAxisCount': bad,
        'flatKey': 'sort',
        'entries': _flatEntries,
      });
      expect(tester.takeException(), isNull, reason: 'crossAxisCount=$bad');
      final delegate = delegateOf(tester) as GridSelectDelegate;
      expect(delegate.crossAxisCount, bad == 4.0 ? 4 : 3, reason: '$bad');
    }

    // Not an integer: the processor rejects it against the schema.
    for (final bad in <Object?>['4', double.nan, null]) {
      final harness = await pumpSelect(tester, {
        'delegate': 'grid',
        'crossAxisCount': bad,
        'flatKey': 'sort',
        'entries': _flatEntries,
      });
      expect(tester.takeException(), isNull, reason: 'crossAxisCount=$bad');
      expectRejected(harness, 'crossAxisCount');
    }
  });

  testWidgets('non-string flatKey is rejected', (tester) async {
    final harness = await pumpSelect(tester, {
      'delegate': 'list',
      'flatKey': 5,
      'entries': _flatEntries,
    });

    expect(tester.takeException(), isNull);
    expectRejected(harness, 'flatKey');
  });

  testWidgets('unknown delegate tokens are rejected', (tester) async {
    for (final token in ['flatten', 'chips', 'nonsense']) {
      final harness = await pumpSelect(tester, {
        'delegate': token,
        'entries': _entries,
      });
      expect(tester.takeException(), isNull, reason: token);
      expectRejected(harness, 'delegate');
    }
  });

  testWidgets('non-string delegate is rejected', (tester) async {
    final harness = await pumpSelect(tester, {
      'delegate': 7,
      'entries': _entries,
    });

    expect(tester.takeException(), isNull);
    expectRejected(harness, 'delegate');
  });

  testWidgets('selection and search survive a parent rebuild', (tester) async {
    final processor = MessageProcessor<ComponentImplementation>(
      catalogs: [FlSelectCatalogItems.asCatalog()],
      validationConfig: ValidationConfig.strict,
    );
    addTearDown(processor.dispose);
    processor.processMessages([
      {
        'version': 'v0.9',
        'createSurface': {'surfaceId': 's', 'catalogId': 'fl_select'},
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 's',
          'components': [
            {
              'id': 'root',
              'component': 'Select',
              'delegate': 'sideNav',
              'search': true,
              'entries': _entries,
            },
          ],
        },
      },
    ]);
    final surface = processor.model.getSurface('s')!;
    final rebuild = ValueNotifier<int>(0);
    addTearDown(rebuild.dispose);

    // Each rebuild hands the builder a fresh, equal payload, as the surface
    // does when it re-renders.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (_, _, _) => A2uiSurface(surface: surface),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A');
    await tester.pumpAndSettle();

    rebuild.value++;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'A',
      reason: 'search text lost after rebuild',
    );

    // A 1 must still count as selected: selecting A 2 adds to it.
    await tester.tap(find.text('A 2'));
    await tester.pumpAndSettle();
    final value = surface.dataModel.get('/root.value') as Map<dynamic, dynamic>;
    expect(value['more'], unorderedEquals(['a1', 'a2']));
  });

  testWidgets('mixed category and flat entries show an error card', (
    tester,
  ) async {
    final category = _entries.first;
    final leaf = _flatEntries.first;

    // Either order must be rejected: the shape check looks at the first
    // entry only, so validation has to catch the stray sibling.
    for (final entries in [
      [category, leaf],
      [leaf, category],
    ]) {
      await pumpSelect(tester, {
        'delegate': 'list',
        'flatKey': 'sort',
        'entries': entries,
      });

      expect(tester.takeException(), isNull);
      expect(find.byType(SelectView), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    }
  });

  testWidgets('search flag toggles the search field', (tester) async {
    await pumpSelect(tester, {
      'delegate': 'sideNav',
      'entries': _entries,
      'search': true,
    });
    expect(find.byType(TextField), findsOneWidget);

    await pumpSelect(tester, {'delegate': 'sideNav', 'entries': _entries});
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

  testWidgets('a cascading category layout drills into nested children', (
    tester,
  ) async {
    await pumpSelect(tester, {
      'delegate': 'tabNav',
      'entries': [
        {
          'type': 'category',
          'id': 'region',
          'name': 'Region',
          'layout': {'kind': 'cascading'},
          'children': [
            {
              'type': 'text',
              'id': 'east',
              'name': 'East',
              'children': [
                {'type': 'text', 'id': 'sh', 'name': 'Shanghai'},
              ],
            },
            {'type': 'text', 'id': 'west', 'name': 'West'},
          ],
        },
      ],
    });

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.text('East'), findsOneWidget);
    expect(find.text('Shanghai'), findsNothing);

    // The branch opens a second column instead of being selected, which is
    // what separates the cascade from the one-level layouts.
    await tester.tap(find.text('East'));
    await tester.pumpAndSettle();
    expect(find.text('Shanghai'), findsOneWidget);
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
