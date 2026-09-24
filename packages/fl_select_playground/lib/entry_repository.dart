import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Simulates a network round-trip so the playground exercises its real
/// skeleton/loading states, mirroring the example app's `entry_data.dart`.
Future<void> _simulateNetworkDelay(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

/// Hard-coded, language-independent select entries for the playground.
///
/// One data set backs every delegate family regardless of the UI language.
/// It is declared in plain Dart after `fl_select/example/lib/entry_data.dart`,
/// except for the cascading sample which is loaded from the `assets/cascading.json`
/// asset (a copy of `fl_select/example/assets/cascading.json`).
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

  SelectEntries get _listInitialSelected => <SelectEntry>{};

  /// List entries applied when the select opens.
  SelectEntries get listSelectedData => listResult ?? _listInitialSelected;

  /// List entries restored by the reset action.
  SelectEntries get listResetData => _listInitialSelected;

  Future<SelectEntries> fetchListData() async {
    await _simulateNetworkDelay(250);
    final entries = <SelectEntry>{
      SelectTextEntry(id: 'newest', name: 'Newest'),
      SelectTextEntry(id: 'oldest', name: 'Oldest'),
      SelectTextEntry(id: 'name_asc', name: 'Name (A to Z)'),
      SelectTextEntry(id: 'name_desc', name: 'Name (Z to A)'),
      SelectTextEntry(id: 'popular', name: 'Most Popular'),
      SelectTextEntry(id: 'rating', name: 'Top Rated'),
    };
    debugPrint('list length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Grid — flat entries for the Grid delegate.
  // -------------------------------------------------------------------------

  /// Latest applied grid selection, if any.
  SelectEntries? gridResult;

  SelectEntries get _gridInitialSelected => <SelectEntry>{};

  /// List entries applied when the select opens.
  SelectEntries get gridSelectedData => gridResult ?? _gridInitialSelected;

  /// List entries restored by the reset action.
  SelectEntries get gridResetData => _gridInitialSelected;

  Future<SelectEntries> fetchGridData() async {
    await _simulateNetworkDelay(250);
    final entries = <SelectEntry>{
      SelectRangeEntry.custom(
        minHintText: noMinHintText,
        maxHintText: noMaxHintText,
      ),
      SelectTextEntry(id: 'a', name: '0-100'),
      SelectTextEntry(id: 'b', name: '100-500'),
      SelectTextEntry(id: 'c', name: '500-1000'),
      SelectTextEntry(id: 'd', name: '1000-2000'),
    };
    debugPrint('grid length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Wrap — flat entries for the Wrap delegate.
  // -------------------------------------------------------------------------

  /// Latest applied grid selection, if any.
  SelectEntries? wrapResult;

  SelectEntries get _wrapInitialSelected => <SelectEntry>{};

  /// List entries applied when the select opens.
  SelectEntries get wrapSelectedData => wrapResult ?? _wrapInitialSelected;

  /// List entries restored by the reset action.
  SelectEntries get wrapResetData => _wrapInitialSelected;

  Future<SelectEntries> fetchWrapData() async {
    await _simulateNetworkDelay(250);
    final entries = <SelectEntry>{
      SelectTextEntry(id: 'a', name: 'Tiger'),
      SelectTextEntry(id: 'b', name: 'Lion'),
      SelectTextEntry(id: 'c', name: 'Bear'),
      SelectTextEntry(id: 'd', name: 'Dog'),
      SelectTextEntry(id: 'e', name: 'Cat'),
      SelectTextEntry(id: 'f', name: 'Elephant'),
      SelectTextEntry(id: 'g', name: 'Monkey'),
      SelectTextEntry(id: 'h', name: 'Pig'),
      SelectTextEntry(id: 'i', name: 'Horse'),
      SelectTextEntry(id: 'j', name: 'Sheep'),
      SelectTextEntry(id: 'k', name: 'Cow'),
      SelectTextEntry(id: 'l', name: 'Chicken'),
      SelectTextEntry(id: 'm', name: 'Duck'),
      SelectTextEntry(id: 'n', name: 'Penguin'),
    };
    debugPrint('wrap length: ${entries.length}');
    return entries;
  }

  // -------------------------------------------------------------------------
  // Cascading — multi-level hierarchy loaded from `assets/cascading.json`.
  // -------------------------------------------------------------------------

  /// Latest applied cascading selection, if any.
  SelectEntries? cascadingResult;

  SelectEntries get _cascadingInitialSelected => <SelectCategoryEntry>{
    SelectCategoryEntry(
      id: 'residential',
      name: '',
      children: {
        SelectTextEntry.any(name: anyEntryText),
      },
    ),
  };

  /// Cascading entries applied when the select opens.
  SelectEntries get cascadingSelectedData =>
      cascadingResult ?? _cascadingInitialSelected;

  /// Cascading entries restored by the reset action.
  SelectEntries get cascadingResetData => _cascadingInitialSelected;

  Future<SelectEntries> fetchCascadingData() async {
    await _simulateNetworkDelay(250);
    final jsonString = await rootBundle.loadString('assets/cascading.json');
    final entries = cascadingFromJson(jsonString)
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            selectionMode: SelectionMode.multiple,
            children: {
              SelectTextEntry.any(name: anyEntryText),
              ...?category.data?.map(_cascadingTextEntry),
            },
          ),
        )
        .toSet();
    debugPrint('cascading length: ${entries.length}');
    return entries;
  }

  /// Recursively turns a [CascadingData] node into a [SelectTextEntry].
  ///
  /// The cascading delegate renders one column per level, so every nested
  /// `data` array becomes another level of children. No `parentId` is written
  /// by hand: each node picks up the id of its direct parent when the entries
  /// are bound.
  SelectTextEntry _cascadingTextEntry(CascadingData node) => SelectTextEntry(
    id: node.id!,
    name: node.name!,
    enabled: node.enabled ?? true,
    children: node.data?.map(_cascadingTextEntry).toSet(),
  );

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
      SelectCategoryEntry(
        id: 'cate1',
        name: 'Sport',
        children: {
          SelectTextEntry(id: 'a', name: 'Football'),
          SelectTextEntry(id: 'b', name: 'Basketball'),
          SelectTextEntry(id: 'c', name: 'Baseball'),
          SelectTextEntry(id: 'd', name: 'Tennis'),
        },
        selectionMode: SelectionMode.single,
        footer: SelectTextEntry(
          id: 'c1-f',
          name: 'Letter Grade',
          children: {
            SelectTextEntry(id: 'f-a', name: 'A'),
            SelectTextEntry(id: 'f-b', name: 'B'),
            SelectTextEntry(id: 'f-c', name: 'C'),
            SelectTextEntry(id: 'f-d', name: 'D'),
            SelectTextEntry(id: 'f-d', name: 'E'),
          },
        ),
        footerSelectionMode: SelectionMode.single,
      ),
      SelectCategoryEntry(
        id: 'cate2',
        name: 'Cuisine',
        header: SelectTextEntry(
          id: 'c2-h',
          name: 'Letter Grade',
          children: {
            SelectTextEntry(id: 'h-a', name: '1'),
            SelectTextEntry(id: 'h-b', name: '2'),
            SelectTextEntry(id: 'h-c', name: '3'),
            SelectTextEntry(id: 'h-d', name: '4'),
            SelectTextEntry(id: 'h-d', name: '5'),
          },
        ),
        headerSelectionMode: SelectionMode.single,
        children: {
          SelectTextEntry(id: 'a', name: 'Chinese'),
          SelectTextEntry(id: 'b', name: 'French'),
          SelectTextEntry(id: 'c', name: 'Indian'),
          SelectTextEntry(id: 'd', name: 'Turkish'),
        },
        selectionMode: SelectionMode.single,
      ),
      SelectCategoryEntry(
        id: 'cate3',
        name: 'Storage (GB)',
        children: {
          SelectIntEntry.custom(
            minHintText: noMinHintText,
            maxHintText: noMaxHintText,
          ),
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
        },
        selectionMode: SelectionMode.single,
      ),
      SelectCategoryEntry(
        id: 'cate4',
        name: 'Animal',
        children: {
          SelectTextEntry(id: 'a', name: 'Tiger'),
          SelectTextEntry(id: 'b', name: 'Lion'),
          SelectTextEntry(id: 'c', name: 'Bear'),
          SelectTextEntry(id: 'd', name: 'Elephant'),
          SelectTextEntry(id: 'e', name: 'Monkey'),
          SelectTextEntry(id: 'f', name: 'Dog'),
          SelectTextEntry(id: 'g', name: 'Cat'),
          SelectTextEntry(id: 'h', name: 'Pig'),
          SelectTextEntry(id: 'i', name: 'Horse'),
          SelectTextEntry(id: 'j', name: 'Sheep'),
          SelectTextEntry(id: 'k', name: 'Cow'),
          SelectTextEntry(id: 'l', name: 'Chicken'),
          SelectTextEntry(id: 'm', name: 'Duck'),
          SelectTextEntry(id: 'n', name: 'Pig'),
        },
      ),
      SelectCategoryEntry(
        id: 'cate5',
        name: 'Price (Dollar)',
        children: {
          SelectRangeEntry(
            id: 'a',
            name: '0-2000000',
            min: 0,
            max: 2000000,
            divisions: 80,
          ),
          SelectRangeEntry.custom(
            minHintText: noMinHintText,
            maxHintText: noMaxHintText,
          ),
        },
        selectionMode: SelectionMode.single,
        layout: const SelectRangeLayout(),
      ),
      SelectCategoryEntry(
        id: 'cate6',
        name: 'Counter',
        children: {
          SelectTextEntry.any(name: anyEntryText),
          SelectTextEntry(id: 'a', name: '1'),
          SelectTextEntry(id: 'b', name: '2'),
          SelectTextEntry(id: 'c', name: '3'),
          SelectTextEntry(id: 'd', name: '4'),
          SelectTextEntry(id: 'e', name: '5'),
          SelectTextEntry(id: 'e', name: '5+'),
        },
        selectionMode: SelectionMode.single,
        layout: const SelectCounterLayout(),
      ),
    };
    debugPrint('two-level length: ${entries.length}');
    return entries;
  }
}

/// Recursive node of the cascading tree stored in `assets/cascading.json`.
class CascadingData {
  CascadingData({this.id, this.name, this.enabled, this.data});

  String? id;
  String? name;
  bool? enabled;
  List<CascadingData>? data;

  factory CascadingData.fromJson(Map<String, dynamic> json) => CascadingData(
    id: json['id'] as String?,
    name: json['name'] as String?,
    enabled: json['enabled'] as bool?,
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => CascadingData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Decodes the `assets/cascading.json` payload into [CascadingData] nodes.
List<CascadingData> cascadingFromJson(String str) =>
    (json.decode(str) as List<dynamic>)
        .map((e) => CascadingData.fromJson(e as Map<String, dynamic>))
        .toList();
