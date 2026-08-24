import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectEntryCodec.fromJson', () {
    test('decodes a full tree with all node types', () {
      final entries = SelectEntryCodec.fromJson([
        {
          'type': 'category',
          'id': 'price',
          'name': 'Price',
          'selectionMode': 'multiple',
          'layout': {'kind': 'grid', 'crossAxisCount': 4},
          'children': [
            {'type': 'any', 'name': 'Any'},
            {
              'type': 'range',
              'id': '0-100',
              'name': '0-100',
              'min': 0,
              'max': 100,
            },
            {
              'type': 'custom',
              'name': 'Custom',
              'min': 0,
              'max': 1000,
            },
          ],
        },
        {
          'type': 'category',
          'id': 'more',
          'name': 'More',
          'children': [
            {
              'type': 'text',
              'id': 'near_subway',
              'name': 'Near Subway',
            },
            {
              'type': 'text',
              'id': 'layout',
              'name': 'Layout',
              'children': [
                {'type': 'text', 'id': '1br', 'name': '1BR'},
                {'type': 'text', 'id': '2br', 'name': '2BR', 'immediate': true},
                {
                  'type': 'text',
                  'id': '3br',
                  'name': '3BR',
                  'enabled': false,
                },
              ],
            },
          ],
        },
      ]);

      expect(entries.length, 2);

      final price = entries.elementAt(0) as SelectCategoryEntry;
      expect(price.id, 'price');
      expect(price.name, 'Price');
      expect(price.selectionMode, SelectionMode.multiple);
      expect(price.layout, isA<SelectGridLayout>());
      expect(price.children!.length, 3);

      // "any" without bounds decodes to a text any entry.
      final any = price.children!.elementAt(0) as SelectChildEntry;
      expect(any.isAny, isTrue);
      expect(any.id, 'any');
      expect(any.parentId, 'price');

      final range = price.children!.elementAt(1) as SelectRangeEntry;
      expect(range.id, '0-100');
      expect(range.min, 0);
      expect(range.max, 100);
      expect(range.parentId, 'price');

      final custom = price.children!.elementAt(2) as SelectRangeEntry;
      expect(custom.isCustom, isTrue);
      expect(custom.id, 'custom');

      // Branch text entry keeps children; flags survive; parentId injected.
      final more = entries.elementAt(1) as SelectCategoryEntry;
      final layout = more.children!.elementAt(1);
      expect(layout.children!.length, 3);
      expect(layout.children!
          .firstWhere((e) => e.id == '2br')
          .immediate, isTrue);
      expect(layout.children!.firstWhere((e) => e.id == '3br').enabled,
          isFalse);
      expect(
        (layout.children!.firstWhere((e) => e.id == '1br')
                as SelectChildEntry)
            .parentId,
        'layout');
    });

    test('any with bounds decodes to a range any entry', () {
      final entries = SelectEntryCodec.fromJson([
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'children': [
            {'type': 'any', 'name': 'All', 'min': 0, 'max': 5000},
          ],
        },
      ]);

      final any = (entries.first as SelectCategoryEntry)
          .children!
          .single as SelectRangeEntry;
      expect(any.isAny, isTrue);
      expect(any.min, 0);
      expect(any.max, 5000);
    });

    test('header and footer decode', () {
      final entries = SelectEntryCodec.fromJson([
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'header': {
            'type': 'text',
            'id': 'h',
            'name': 'Header',
            'children': [
              {'type': 'text', 'id': 'h-a', 'name': 'A'},
            ],
          },
          'footer': {
            'type': 'text',
            'id': 'f',
            'name': 'Footer',
            'children': [
              {'type': 'text', 'id': 'f-a', 'name': 'A'},
            ],
          },
          'children': [
            {'type': 'text', 'id': 'a', 'name': 'A'},
          ],
        },
      ]);

      final category = entries.first as SelectCategoryEntry;
      expect(category.header!.id, 'h');
      expect(category.footer!.id, 'f');
      // Header/footer subtrees also get parentId injected.
      expect(
        (category.header!.children!.single as SelectChildEntry).parentId,
        'h',
      );
    });

    test('double bounds decode as doubles', () {
      final entries = SelectEntryCodec.fromJson([
        {
          'type': 'category',
          'id': 'c',
          'name': 'C',
          'children': [
            {
              'type': 'range',
              'id': 'r',
              'name': 'R',
              'min': 0.5,
              'max': 1.5,
            },
          ],
        },
      ]);

      final range =
          (entries.first as SelectCategoryEntry).children!.single
              as SelectRangeEntry;
      expect(range.min, isA<double>());
    });

    test('decodes all layout kinds', () {
      SelectLayout? layoutFor(Map<String, dynamic> layout) {
        final entries = SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'id': 'c',
            'name': 'C',
            'layout': layout,
            'children': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
            ],
          },
        ]);
        return (entries.first as SelectCategoryEntry).layout;
      }

      expect(layoutFor({'kind': 'list'}), isA<SelectListLayout>());
      expect(
        layoutFor({
          'kind': 'grid',
          'crossAxisCount': 3,
          'childAspectRatio': 1.5,
        }),
        isA<SelectGridLayout>(),
      );
      expect(
        layoutFor({'kind': 'chip', 'spacing': 8}),
        isA<SelectChipLayout>(),
      );
      expect(layoutFor({'kind': 'counter'}), isA<SelectCounterLayout>());
      expect(layoutFor({'kind': 'range'}), isA<SelectRangeLayout>());
    });

    test('throws on malformed input', () {
      expect(() => SelectEntryCodec.fromJson([]), throwsFormatException);

      expect(
        () => SelectEntryCodec.fromJson([
          {'id': 'a', 'name': 'A'},
        ]),
        throwsFormatException, // missing "type"
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {'type': 'unknown', 'id': 'a', 'name': 'A'},
        ]),
        throwsFormatException,
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'id': 'c',
            'name': 'C',
            'children': <dynamic>[],
          },
        ]),
        throwsFormatException, // empty children
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'name': 'C',
            'children': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
            ],
          },
        ]),
        throwsFormatException, // missing id
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'text',
            'id': 'a',
            'children': <dynamic>[],
          },
        ]),
        throwsFormatException, // missing name
      );

      expect(
        () => SelectEntryCodec.fromJson(['not-a-map']),
        throwsFormatException,
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'id': 'c',
            'name': 'C',
            'selectionMode': 'bogus',
            'children': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
            ],
          },
        ]),
        throwsFormatException,
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'id': 'c',
            'name': 'C',
            'layout': {'kind': 'bogus'},
            'children': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
            ],
          },
        ]),
        throwsFormatException,
      );

      expect(
        () => SelectEntryCodec.fromJson([
          {
            'type': 'category',
            'id': 'c',
            'name': 'C',
            'layout': {'kind': 'grid'},
            'children': [
              {'type': 'text', 'id': 'a', 'name': 'A'},
            ],
          },
        ]),
        throwsFormatException, // grid without crossAxisCount
      );
    });
  });

  group('SelectEntryCodec.toJson', () {
    Set<SelectEntry> buildTree() => {
          SelectCategoryEntry.children(
            id: 'price',
            name: 'price',
            selectionMode: SelectionMode.multiple,
            layout: const SelectGridLayout(crossAxisCount: 4),
            children: {
              SelectTextEntry.any(parentId: 'price', name: 'any'),
              SelectRangeEntry(
                id: '0-100',
                name: '0-100',
                min: 0,
                max: 100,
              ),
              SelectRangeEntry.custom(
                name: 'custom',
                min: 0,
                max: 1000,
              ),
            },
          ),
        };

    test('round-trips a hand-built tree', () {
      final original = buildTree();
      final json = SelectEntryCodec.toJson(original);
      final decoded = SelectEntryCodec.fromJson(
        json.map((e) => e).toList(),
      );

      final price = decoded.first as SelectCategoryEntry;
      expect(price.id, 'price');
      expect(price.selectionMode, SelectionMode.multiple);
      expect(price.layout, isA<SelectGridLayout>());

      final ids = price.children!.map((e) => e.id).toList();
      expect(ids, containsAll(['any', '0-100', 'custom']));

      final range = price.children!.firstWhere((e) => e.id == '0-100')
          as SelectRangeEntry;
      expect(range.min, 0);
      expect(range.max, 100);

      final custom = price.children!.firstWhere((e) => e.id == 'custom')
          as SelectRangeEntry;
      expect(custom.min, 0);
      expect(custom.max, 1000);
    });

    test('emits a compact JSON shape', () {
      final json = SelectEntryCodec.toJson(buildTree());
      final category = json.single;

      expect(category['type'], 'category');
      expect(category['id'], 'price');
      expect(category['selectionMode'], 'multiple');
      expect((category['layout'] as Map)['kind'], 'grid');
      expect(category['layout']['crossAxisCount'], 4);

      final children = category['children'] as List;
      final anyNode =
          children.firstWhere((c) => c['type'] == 'any') as Map;
      expect(anyNode['name'], 'any');
      expect(anyNode.containsKey('id'), isFalse);

      final customNode =
          children.firstWhere((c) => c['type'] == 'custom') as Map;
      expect(customNode.containsKey('id'), isFalse);
      expect(customNode['max'], 1000);
    });

    test('omits defaults for enabled and immediate', () {
      final json = SelectEntryCodec.toJson(buildTree());
      final category = json.single;
      expect(category.containsKey('enabled'), isFalse);
      expect(category.containsKey('immediate'), isFalse);

      final children = category['children'] as List;
      final rangeNode =
          children.firstWhere((c) => c['type'] == 'range') as Map;
      expect(rangeNode.containsKey('immediate'), isFalse);
    });

    test('emits disabled and immediate flags', () {
      final entries = {
        SelectCategoryEntry.children(
          id: 'c',
          name: 'C',
          children: {
            SelectTextEntry.name(
              id: 'a',
              name: 'A',
              immediate: true,
            ),
            SelectTextEntry.name(
              id: 'b',
              name: 'B',
              enabled: false,
            ),
          },
        ),
      };

      final children =
          (SelectEntryCodec.toJson(entries).single['children']) as List;
      final a = children.firstWhere((c) => c['id'] == 'a') as Map;
      final b = children.firstWhere((c) => c['id'] == 'b') as Map;
      expect(a['immediate'], isTrue);
      expect(b['enabled'], isFalse);
    });

    test('serializes header and footer', () {
      final entries = {
        SelectCategoryEntry.children(
          id: 'c',
          name: 'C',
          header: SelectTextEntry.children(
            id: 'h',
            name: 'Header',
            children: {
              SelectTextEntry.name(id: 'h-a', name: 'A'),
            },
          ),
          footer: SelectTextEntry.children(
            id: 'f',
            name: 'Footer',
            children: {
              SelectTextEntry.name(id: 'f-a', name: 'A'),
            },
          ),
          children: {
            SelectTextEntry.name(id: 'a', name: 'A'),
          },
        ),
      };

      final json = SelectEntryCodec.toJson(entries).single;
      expect((json['header'] as Map)['id'], 'h');
      expect((json['footer'] as Map)['id'], 'f');
    });

    test('throws UnsupportedError on custom subclasses', () {
      final rogue = _RogueEntry();
      expect(
        () => SelectEntryCodec.toJson({rogue}),
        throwsUnsupportedError,
      );
    });
  });

  group('SelectEntryCodec + toQueryMap integration', () {
    test('decoded trees produce query parameters', () {
      final entries = SelectEntryCodec.fromJson([
        {
          'type': 'category',
          'id': 'price',
          'name': 'Price',
          'children': [
            {'type': 'any', 'name': 'Any'},
            {'type': 'range', 'id': '0-100', 'name': '0-100', 'min': 0, 'max': 100},
          ],
        },
        {
          'type': 'category',
          'id': 'more',
          'name': 'More',
          'children': [
            {'type': 'text', 'id': 'near_subway', 'name': 'Near Subway'},
          ],
        },
      ]);

      // Mirrors how delegates hand selections to `toQueryMap`: the owning
      // category tree, whose leaves get flattened by key.
      final queryMap = entries.toQueryMap();
      // "any" leaf contributes its parent id; range leaves contribute
      // "min-max"; branch entries are flattened into the category key.
      expect(queryMap['price'], ['price', '0-100']);
      expect(queryMap['more'], ['near_subway']);

      final query = entries.toQueryParameters(encode: false);
      expect(query, contains('price=0-100'));
      expect(query, contains('more=near_subway'));
    });
  });
}

/// A SelectEntry subclass outside the built-in family, used to verify that
/// [SelectEntryCodec.toJson] fails loudly instead of silently dropping data.
class _RogueEntry extends SelectEntry<dynamic> {
  _RogueEntry() : super(id: 'rogue', name: 'Rogue');
}
