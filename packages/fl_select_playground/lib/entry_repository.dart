import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';

/// Simulates a network round-trip so the playground exercises its real
/// skeleton/loading states, mirroring the example app's `entry_data.dart`.
Future<void> _simulateNetworkDelay(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

/// Hard-coded, language-independent select entries for the playground.
///
/// One data set backs every delegate family regardless of the UI language.
/// It is declared in plain Dart after `fl_select/example/lib/entry_data.dart`
/// instead of being loaded from JSON assets.
///
/// Each sample exposes the trio the playground expects: a `fetch…Data()`
/// entries loader, a `…SelectedData` initial selection and a `…ResetData`
/// selection restored by the reset action.
class EntryRepository {
  EntryRepository({
    this.anyEntryText = 'Any',
    this.noMinHintText = 'No min',
    this.noMaxHintText = 'No max',
  });

  /// Label of the "Any" pseudo entry inserted into the samples below.
  final String anyEntryText;

  /// Hint text of the custom range entry's minimum input field.
  final String noMinHintText;

  /// Hint text of the custom range entry's maximum input field.
  final String noMaxHintText;

  // -------------------------------------------------------------------------
  // List — flat entries for the List delegate.
  // -------------------------------------------------------------------------

  /// Latest applied list selection, if any.
  SelectEntries? listResult;

  SelectEntries get _listInitialSelected => <SelectTextEntry>{
    SelectTextEntry.id(id: 'newest'),
  };

  /// List entries applied when the select opens.
  SelectEntries get listSelectedData => listResult ?? _listInitialSelected;

  /// List entries restored by the reset action.
  SelectEntries get listResetData => _listInitialSelected;

  Future<SelectEntries> fetchListData() async {
    await _simulateNetworkDelay(250);
    final entries = <SelectTextEntry>{
      SelectTextEntry.name(id: 'newest', name: 'Newest', immediate: true),
      SelectTextEntry.name(id: 'oldest', name: 'Oldest', immediate: true),
      SelectTextEntry.name(
        id: 'name_asc',
        name: 'Name (A to Z)',
        immediate: true,
      ),
      SelectTextEntry.name(
        id: 'name_desc',
        name: 'Name (Z to A)',
        immediate: true,
      ),
      SelectTextEntry.name(
        id: 'popular',
        name: 'Most Popular',
        immediate: true,
      ),
      SelectTextEntry.name(id: 'rating', name: 'Top Rated', immediate: true),
    };
    debugPrint('list length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Counters — two counter categories for the Grid / Wrap delegates.
  // -------------------------------------------------------------------------

  /// Latest applied counters selection, if any.
  SelectEntries? counterResult;

  SelectEntries get _counterInitialSelected => <SelectCategoryEntry>{
    SelectCategoryEntry(
      id: 'apples',
      name: '',
      children: {SelectTextEntry(parentId: 'apples', id: '2', name: '')},
    ),
    SelectCategoryEntry(
      id: 'oranges',
      name: '',
      children: {SelectTextEntry(parentId: 'oranges', id: '1', name: '')},
    ),
  };

  /// Counters entries applied when the select opens.
  SelectEntries get counterSelectedData =>
      counterResult ?? _counterInitialSelected;

  /// Counters entries restored by the reset action.
  SelectEntries get counterResetData => <SelectCategoryEntry>{
    SelectCategoryEntry(
      id: 'apples',
      name: '',
      children: {SelectTextEntry.any(parentId: 'apples', name: '')},
    ),
    SelectCategoryEntry(
      id: 'oranges',
      name: '',
      children: {SelectTextEntry.any(parentId: 'oranges', name: '')},
    ),
  };

  Future<SelectEntries> fetchCounterData() async {
    await _simulateNetworkDelay(450);
    final entries = <SelectCategoryEntry>{
      SelectCategoryEntry.children(
        id: 'apples',
        name: 'Apples',
        selectionMode: SelectionMode.single,
        layout: const SelectCounterLayout(),
        children: {
          SelectTextEntry.any(parentId: '', name: anyEntryText),
          SelectTextEntry.name(id: '0', name: 'None'),
          SelectTextEntry.name(id: '1', name: '1'),
          SelectTextEntry.name(id: '2', name: '2'),
          SelectTextEntry.name(id: '3', name: '3'),
          SelectTextEntry.name(id: '4', name: '4'),
          SelectTextEntry.name(id: '5', name: '5+'),
        },
      ),
      SelectCategoryEntry.children(
        id: 'oranges',
        name: 'Oranges',
        selectionMode: SelectionMode.single,
        layout: const SelectCounterLayout(),
        children: {
          SelectTextEntry.any(parentId: '', name: anyEntryText),
          SelectTextEntry.name(id: '1', name: '1'),
          SelectTextEntry.name(id: '2', name: '2'),
          SelectTextEntry.name(id: '3', name: '3'),
          SelectTextEntry.name(id: '4', name: '4'),
          SelectTextEntry.name(id: '5', name: '5+'),
        },
      ),
    };
    debugPrint('counters length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Cascading — two-level hierarchy for the Cascading delegate.
  // -------------------------------------------------------------------------

  /// Latest applied cascading selection, if any.
  SelectEntries? cascadingResult;

  SelectEntries get _cascadingInitialSelected => <SelectCategoryEntry>{
    SelectCategoryEntry(
      id: 'animals',
      name: '',
      children: {SelectTextEntry.any(parentId: 'animals', name: '')},
    ),
  };

  /// Cascading entries applied when the select opens.
  SelectEntries get cascadingSelectedData =>
      cascadingResult ?? _cascadingInitialSelected;

  /// Cascading entries restored by the reset action.
  SelectEntries get cascadingResetData => _cascadingInitialSelected;

  Future<SelectEntries> fetchCascadingData() async {
    await _simulateNetworkDelay(250);
    final entries = <SelectCategoryEntry>{
      SelectCategoryEntry.children(
        id: 'animals',
        name: 'Animals',
        selectionMode: SelectionMode.multiple,
        children: {
          SelectTextEntry.any(
            parentId: '',
            name: anyEntryText,
            immediate: true,
          ),
          SelectTextEntry.children(
            id: 'mammals',
            name: 'Mammals',
            children: {
              SelectTextEntry.name(id: 'tiger', name: 'Tiger'),
              SelectTextEntry.name(id: 'lion', name: 'Lion'),
              SelectTextEntry.name(id: 'bear', name: 'Bear'),
              SelectTextEntry.name(id: 'elephant', name: 'Elephant'),
            },
          ),
          SelectTextEntry.children(
            id: 'birds',
            name: 'Birds',
            children: {
              SelectTextEntry.name(id: 'penguin', name: 'Penguin'),
              SelectTextEntry.name(id: 'eagle', name: 'Eagle'),
              SelectTextEntry.name(id: 'parrot', name: 'Parrot'),
              SelectTextEntry.name(id: 'owl', name: 'Owl'),
            },
          ),
          SelectTextEntry.children(
            id: 'reptiles',
            name: 'Reptiles',
            children: {
              SelectTextEntry.name(id: 'crocodile', name: 'Crocodile'),
              SelectTextEntry.name(id: 'turtle', name: 'Turtle'),
              SelectTextEntry.name(id: 'snake', name: 'Snake'),
              SelectTextEntry.name(id: 'lizard', name: 'Lizard'),
            },
          ),
          SelectTextEntry.children(
            id: 'sea_life',
            name: 'Sea Life',
            children: {
              SelectTextEntry.name(id: 'dolphin', name: 'Dolphin'),
              SelectTextEntry.name(id: 'shark', name: 'Shark'),
              SelectTextEntry.name(id: 'whale', name: 'Whale'),
              SelectTextEntry.name(id: 'octopus', name: 'Octopus'),
            },
          ),
        },
      ),
    };
    debugPrint('cascading length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Two-level — categories for the TabNav / SideNav / Expandable delegates.
  // -------------------------------------------------------------------------

  /// Latest applied two-level selection, if any.
  SelectEntries? twoLevelResult;

  final Set<SelectCategoryEntry> _twoLevelInitialSelected =
      <SelectCategoryEntry>{};

  /// Two-level entries applied when the select opens.
  SelectEntries get twoLevelSelectedData =>
      twoLevelResult ?? _twoLevelInitialSelected;

  /// Two-level entries restored by the reset action.
  SelectEntries get twoLevelResetData => _twoLevelInitialSelected;

  Future<SelectEntries> fetchTwoLevelData() async {
    await _simulateNetworkDelay(850);
    final entries = <SelectCategoryEntry>{
      SelectCategoryEntry.children(
        id: 'category',
        name: 'Category',
        selectionMode: SelectionMode.multiple,
        layout: const SelectGridLayout(
          crossAxisCount: 2,
          childAspectRatio: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        children: {
          SelectTextEntry.name(id: 'phones', name: 'Phones'),
          SelectTextEntry.name(id: 'laptops', name: 'Laptops'),
          SelectTextEntry.name(id: 'tablets', name: 'Tablets'),
          SelectTextEntry.name(id: 'watches', name: 'Watches'),
          SelectTextEntry.name(id: 'headphones', name: 'Headphones'),
          SelectTextEntry.name(id: 'cameras', name: 'Cameras'),
        },
      ),
      SelectCategoryEntry.children(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.multiple,
        layout: const SelectRangeLayout(toText: 'to'),
        children: {
          SelectIntEntry(
            id: '0-25',
            name: '\$0-\$25',
            min: 0,
            max: 25,
            divisions: 40,
          ),
          SelectIntEntry(
            id: '25-50',
            name: '\$25-\$50',
            min: 25,
            max: 50,
            divisions: 40,
          ),
          SelectIntEntry(
            id: '50-100',
            name: '\$50-\$100',
            min: 50,
            max: 100,
            divisions: 40,
          ),
          SelectIntEntry(
            id: '100-250',
            name: '\$100-\$250',
            min: 100,
            max: 250,
            divisions: 40,
          ),
          SelectIntEntry(
            id: '250-500',
            name: '\$250-\$500',
            min: 250,
            max: 500,
            divisions: 40,
          ),
          SelectIntEntry(
            id: '500-1000',
            name: '\$500-\$1000',
            min: 500,
            max: 1000,
            divisions: 40,
          ),
          SelectIntEntry.custom(
            minHintText: noMinHintText,
            maxHintText: noMaxHintText,
          ),
        },
      ),
      SelectCategoryEntry.children(
        id: 'storage',
        name: 'Storage (GB)',
        selectionMode: SelectionMode.multiple,
        layout: const SelectGridLayout(
          crossAxisCount: 3,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        children: {
          SelectRangeEntry(id: '0-64', name: '0-64', min: 0, max: 64),
          SelectRangeEntry(id: '64-128', name: '64-128', min: 64, max: 128),
          SelectRangeEntry(id: '128-256', name: '128-256', min: 128, max: 256),
          SelectRangeEntry(id: '256-512', name: '256-512', min: 256, max: 512),
          SelectRangeEntry(
            id: '512-1024',
            name: '512-1024',
            min: 512,
            max: 1024,
          ),
          SelectRangeEntry(
            id: '1024-2048',
            name: '1024-2048',
            min: 1024,
            max: 2048,
          ),
          SelectIntEntry.custom(
            minHintText: noMinHintText,
            maxHintText: noMaxHintText,
          ),
        },
      ),
      SelectCategoryEntry.children(
        id: 'features',
        name: 'Features',
        selectionMode: SelectionMode.multiple,
        layout: const SelectGridLayout(
          crossAxisCount: 3,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        children: {
          SelectTextEntry.name(id: 'wireless', name: 'Wireless'),
          SelectTextEntry.name(id: 'waterproof', name: 'Waterproof'),
          SelectTextEntry.name(id: 'portable', name: 'Portable'),
          SelectTextEntry.name(id: 'rechargeable', name: 'Rechargeable'),
          SelectTextEntry.name(id: 'foldable', name: 'Foldable'),
          SelectTextEntry.name(id: 'lightweight', name: 'Lightweight'),
        },
      ),
      SelectCategoryEntry.children(
        id: 'availability',
        name: 'Availability',
        selectionMode: SelectionMode.single,
        layout: const SelectWrapLayout(),
        children: {
          SelectTextEntry.name(id: 'in_stock', name: 'In Stock'),
          SelectTextEntry.name(id: 'pre_order', name: 'Pre-order'),
          SelectTextEntry.name(id: 'backordered', name: 'Backordered'),
          SelectTextEntry.name(id: 'discontinued', name: 'Discontinued'),
        },
      ),
    };
    debugPrint('two-level length: ${entries.length}');
    return entries;
  }
}
