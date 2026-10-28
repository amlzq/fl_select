import 'package:fl_select/fl_select.dart';
import 'package:flutter_test/flutter_test.dart';

List<String?> _names(Iterable<SelectEntry> es) =>
    es.map((e) => e.name).toList();

void main() {
  group('defaultSelectSearchPredicate', () {
    test('is case-insensitive substring on name', () {
      final e = SelectTextEntry(id: '1', name: 'Apple Pie');
      expect(defaultSelectSearchPredicate(e, 'apple'), isTrue);
      expect(defaultSelectSearchPredicate(e, 'PIE'), isTrue);
      expect(defaultSelectSearchPredicate(e, 'xyz'), isFalse);
    });

    test('null name never matches', () {
      expect(
        defaultSelectSearchPredicate(SelectChildEntry(id: '1'), 'a'),
        isFalse,
      );
    });
  });

  group('filterEntriesForSearch', () {
    final flat = <SelectEntry>[
      SelectTextEntry(id: '1', name: 'Apple'),
      SelectTextEntry(id: '2', name: 'Banana'),
      SelectTextEntry(id: '3', name: 'Pineapple'),
    ];

    test('empty query returns the original list', () {
      expect(identical(filterEntriesForSearch(flat, ''), flat), isTrue);
    });

    test('flat list is filtered directly', () {
      expect(_names(filterEntriesForSearch(flat, 'apple')), [
        'Apple',
        'Pineapple',
      ]);
      expect(filterEntriesForSearch(flat, 'zzz'), isEmpty);
    });

    test('custom predicate matches other fields', () {
      final r = filterEntriesForSearch(
        flat,
        '2',
        predicate: (e, q) => e.id == q,
      );
      expect(_names(r), ['Banana']);
    });

    List<SelectEntry> tree() => [
      SelectCategoryEntry(
        id: 'c1',
        name: 'Fruits',
        children: {
          SelectTextEntry(id: 'a', name: 'Apple'),
          SelectTextEntry(
            id: 'b',
            name: 'Berries',
            children: {
              SelectTextEntry(id: 'b1', name: 'Strawberry'),
              SelectTextEntry(id: 'b2', name: 'Blueberry'),
            },
          ),
          SelectTextEntry(id: 'k', name: 'Kiwi'),
        },
      ),
      SelectCategoryEntry(
        id: 'c2',
        name: 'Veg',
        children: {SelectTextEntry(id: 'v', name: 'Carrot')},
      ),
    ];

    test('category tree keeps only matching branches', () {
      final r = filterEntriesForSearch(tree(), 'straw');
      expect(_names(r), ['Fruits']);
      final fruits = r.single as SelectCategoryEntry;
      expect(_names(fruits.children!), ['Berries']);
      final berries = fruits.children!.single as SelectChildEntry;
      expect(_names(berries.children!), ['Strawberry']);
    });

    test('a leaf-only node match keeps just that leaf', () {
      final r = filterEntriesForSearch(tree(), 'kiwi');
      final fruits = r.single as SelectCategoryEntry;
      expect(_names(fruits.children!), ['Kiwi']);
    });

    test('a matching category with no matching children is kept empty', () {
      final r = filterEntriesForSearch(tree(), 'veg');
      expect(_names(r), ['Veg']);
      expect((r.single as SelectCategoryEntry).children, isEmpty);
    });

    test('no match drops everything', () {
      expect(filterEntriesForSearch(tree(), 'nothing'), isEmpty);
    });

    test('non-category top-level entries beside categories are filtered', () {
      final mixed = <SelectEntry>[
        ...tree(),
        SelectTextEntry(id: 'x', name: 'Extra'),
      ];
      expect(_names(filterEntriesForSearch(mixed, 'extra')), ['Extra']);
    });

    test('non-child generic entry falls back to the predicate', () {
      final r = filterEntriesForSearch([
        SelectCategoryEntry(
          id: 'c',
          name: 'C',
          children: {
            SelectRangeEntry<int, int>(id: 'r', name: 'Range', min: 0, max: 10),
          },
        ),
      ], 'range');
      expect(_names((r.single as SelectCategoryEntry).children!), ['Range']);
    });
  });
}
