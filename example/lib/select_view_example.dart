import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'log.dart';
import 'widgets/show_select_result.dart';

class SelectViewExamplePage extends StatelessWidget {
  const SelectViewExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SelectView')),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CascadingSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: CascadingSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.children(
                            id: 'l1-a',
                            name: 'A',
                            children: {
                              SelectTextEntry.any(
                                  parentId: 'l1-a', name: 'Any'),
                              SelectTextEntry.name(
                                  id: 'l2-a', name: 'Football'),
                              SelectTextEntry.name(
                                  id: 'l2-b', name: 'Basketball'),
                              SelectTextEntry.name(
                                  id: 'l2-c', name: 'Baseball'),
                              SelectTextEntry.name(
                                  id: 'l2-d', name: 'Swimming'),
                            },
                          ),
                          SelectTextEntry.name(id: 'l1-b', name: 'B'),
                          SelectTextEntry.name(id: 'l1-c', name: 'C'),
                          SelectTextEntry.name(id: 'l1-d', name: 'D'),
                        },
                        selectionMode: SelectionMode.multiple,
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                          SelectTextEntry.name(id: 'g', name: 'Cat'),
                          SelectTextEntry.name(id: 'h', name: 'Pig'),
                          SelectTextEntry.name(id: 'i', name: 'Horse'),
                          SelectTextEntry.name(id: 'j', name: 'Sheep'),
                          SelectTextEntry.name(id: 'k', name: 'Cow'),
                          SelectTextEntry.name(id: 'l', name: 'Chicken'),
                          SelectTextEntry.name(id: 'm', name: 'Duck'),
                          SelectTextEntry.name(id: 'n', name: 'Pig'),
                          SelectTextEntry.name(id: 'o', name: 'Horse'),
                          SelectTextEntry.name(id: 'p', name: 'Sheep'),
                          SelectTextEntry.name(id: 'q', name: 'Cow'),
                        },
                        selectionMode: SelectionMode.multiple,
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Football'),
                          SelectTextEntry.name(id: 'b', name: 'Basketball'),
                          SelectTextEntry.name(id: 'c', name: 'Baseball'),
                          SelectTextEntry.name(id: 'd', name: 'Tennis'),
                        },
                        footer: SelectTextEntry.children(
                          id: 'c3-f',
                          name: 'Footer',
                          children: {
                            SelectTextEntry.name(id: 'f-a', name: 'Blue'),
                            SelectTextEntry.name(id: 'f-b', name: 'Red'),
                            SelectTextEntry.name(id: 'f-c', name: 'Green'),
                            SelectTextEntry.name(id: 'f-d', name: 'Yellow'),
                          },
                        ),
                        footerSelectionMode: SelectionMode.single,
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        header: SelectTextEntry.children(
                          id: 'c4-h',
                          name: 'Header',
                          children: {
                            SelectTextEntry.name(id: 'h-a', name: 'Football'),
                            SelectTextEntry.name(id: 'h-b', name: 'Basketball'),
                            SelectTextEntry.name(id: 'h-c', name: 'Baseball'),
                            SelectTextEntry.name(id: 'h-d', name: 'Swimming'),
                          },
                        ),
                        headerSelectionMode: SelectionMode.single,
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                      ),
                    },
                    selectionMode: SelectionMode.single,
                    sideBarTheme: const SelectSideBarTheme(width: 100),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                    searchEnabled: true,
                    searchHintText: 'Search items...',
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
                    },
                    searchDebounceDuration: const Duration(milliseconds: 300),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'CascadingSelectDelegate-1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: CascadingSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: null,
                      ),
                      SelectCategoryEntry(
                        id: 'cate2',
                        name: 'Cate 2',
                        children: null,
                      ),
                      SelectCategoryEntry(
                        id: 'cate3',
                        name: 'Cate 3',
                        children: null,
                      ),
                      SelectCategoryEntry(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: null,
                      ),
                      SelectCategoryEntry(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: null,
                      ),
                      // SelectTextEntry.name(id: 'a', name: 'Tiger'),
                      // SelectTextEntry.name(id: 'b', name: 'Lion'),
                      // SelectTextEntry.name(id: 'c', name: 'Bear'),
                      // SelectTextEntry.name(id: 'd', name: 'Elephant'),
                    },
                    selectionMode: SelectionMode.single,
                    sideBarTheme: const SelectSideBarTheme(width: 100),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                    searchEnabled: true,
                    searchHintText: 'Search items...',
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
                    },
                    searchDebounceDuration: const Duration(milliseconds: 300),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'GridSelectDelegate-1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: () async => {
                      SelectRangeEntry.custom(),
                      SelectTextEntry.name(id: 'a', name: 'A'),
                      SelectTextEntry.name(id: 'b', name: 'B'),
                      SelectTextEntry.name(id: 'c', name: 'C'),
                      SelectTextEntry.name(id: 'd', name: 'D'),
                    },
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // selectionMode: SelectionMode.multiple,
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint('toQueryMap: ${selected.toQueryMap()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'GridSelectDelegate-2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                          SelectRangeEntry.custom(),
                        },
                        // selectionMode: SelectionMode.single,
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                          SelectTextEntry.name(id: 'g', name: 'Cat'),
                          SelectTextEntry.name(id: 'h', name: 'Pig'),
                          SelectTextEntry.name(id: 'i', name: 'Horse'),
                          SelectTextEntry.name(id: 'j', name: 'Sheep'),
                          SelectTextEntry.name(id: 'k', name: 'Cow'),
                          SelectTextEntry.name(id: 'l', name: 'Chicken'),
                          SelectTextEntry.name(id: 'm', name: 'Duck'),
                          SelectTextEntry.name(id: 'n', name: 'Pig'),
                          SelectTextEntry.name(id: 'o', name: 'Horse'),
                          SelectTextEntry.name(id: 'p', name: 'Sheep'),
                          SelectTextEntry.name(id: 'q', name: 'Cow'),
                        },
                        // selectionMode: SelectionMode.single,
                        layout: const SelectChipLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'FlattenSelectDelegate 1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: () async => {
                      SelectTextEntry.name(id: 'a', name: 'Tiger'),
                      SelectTextEntry.name(id: 'b', name: 'Lion'),
                      SelectTextEntry.name(id: 'c', name: 'Bear'),
                      SelectTextEntry.name(id: 'd', name: 'Elephant'),
                      SelectTextEntry.name(id: 'e', name: 'Monkey'),
                      SelectTextEntry.name(id: 'f', name: 'Dog'),
                      SelectTextEntry.name(id: 'g', name: 'Cat'),
                      SelectTextEntry.name(id: 'h', name: 'Pig'),
                      SelectTextEntry.name(id: 'i', name: 'Horse'),
                      SelectTextEntry.name(id: 'j', name: 'Sheep'),
                      SelectTextEntry.name(id: 'k', name: 'Cow'),
                      SelectTextEntry.name(id: 'l', name: 'Chicken'),
                      SelectTextEntry.name(id: 'm', name: 'Duck'),
                      SelectTextEntry.name(id: 'n', name: 'Pig'),
                      SelectTextEntry.name(id: 'o', name: 'Horse'),
                      SelectTextEntry.name(id: 'p', name: 'Sheep'),
                      SelectTextEntry.name(id: 'q', name: 'Cow'),
                    },
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint('toQueryMap: ${selected.toQueryMap()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'FlattenSelectDelegate 2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate2',
                        name: 'Cate 2',
                        children: {
                          SelectRangeEntry.custom(),
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectGridLayout(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'ListSelectDelegate 1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: () async => {
                      SelectTextEntry.name(id: 'a', name: 'A'),
                      SelectTextEntry.name(id: 'b', name: 'B'),
                      SelectTextEntry.name(id: 'c', name: 'C'),
                      SelectTextEntry.name(id: 'd', name: 'D'),
                    },
                    searchEnabled: true,
                    searchHintText: 'Search items...',
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
                    },
                    searchDebounceDuration: const Duration(milliseconds: 300),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'ListSelectDelegate 2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectRangeEntry.custom(),
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                          SelectTextEntry.name(id: 'g', name: 'Cat'),
                          SelectTextEntry.name(id: 'h', name: 'Pig'),
                          SelectTextEntry.name(id: 'i', name: 'Horse'),
                          SelectTextEntry.name(id: 'j', name: 'Sheep'),
                          SelectTextEntry.name(id: 'k', name: 'Cow'),
                          SelectTextEntry.name(id: 'l', name: 'Chicken'),
                          SelectTextEntry.name(id: 'm', name: 'Duck'),
                          SelectTextEntry.name(id: 'n', name: 'Pig'),
                          SelectTextEntry.name(id: 'o', name: 'Horse'),
                          SelectTextEntry.name(id: 'p', name: 'Sheep'),
                          SelectTextEntry.name(id: 'q', name: 'Cow'),
                        },
                        layout: const SelectChipLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectGridLayout(
                          crossAxisCount: 3,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.single,
                    searchEnabled: true,
                    searchHintText: 'Search items...',
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
                    },
                    searchDebounceDuration: const Duration(milliseconds: 300),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint(
                        'toQueryParameters: ${selected.toQueryParameters()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
