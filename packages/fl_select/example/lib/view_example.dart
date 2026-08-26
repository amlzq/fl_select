import 'package:example/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'log.dart';
import 'show_select_result.dart';

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
                    entries: {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.children(
                            id: 'l1-a',
                            name: 'Sport',
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
                          SelectTextEntry.name(id: 'l1-b', name: 'Cooking'),
                          SelectTextEntry.name(id: 'l1-c', name: 'Art'),
                          SelectTextEntry.children(
                            id: 'l1-d',
                            name: 'Music',
                            children: {
                              SelectTextEntry.any(
                                  parentId: 'l1-d', name: 'Any'),
                              SelectTextEntry.name(id: 'l2-a', name: 'Blues'),
                              SelectTextEntry.name(id: 'l2-b', name: 'Jazz'),
                              SelectTextEntry.name(id: 'l2-c', name: 'Hip hop'),
                              SelectTextEntry.name(id: 'l2-d', name: 'Rock'),
                            },
                          ),
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
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'f-a', name: 'A'),
                            SelectTextEntry.name(id: 'f-b', name: 'B'),
                            SelectTextEntry.name(id: 'f-c', name: 'C'),
                            SelectTextEntry.name(id: 'f-d', name: 'D'),
                          },
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        header: SelectTextEntry.children(
                          id: 'c4-h',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'h-a', name: 'A'),
                            SelectTextEntry.name(id: 'h-b', name: 'B'),
                            SelectTextEntry.name(id: 'h-c', name: 'C'),
                            SelectTextEntry.name(id: 'h-d', name: 'D'),
                          },
                        ),
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Mathematics'),
                          SelectTextEntry.name(id: 'b', name: 'Language'),
                          SelectTextEntry.name(id: 'c', name: 'Science'),
                          SelectTextEntry.name(id: 'd', name: 'History'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'North'),
                          SelectTextEntry.name(id: 'b', name: 'South'),
                          SelectTextEntry.name(id: 'c', name: 'East'),
                          SelectTextEntry.name(id: 'd', name: 'West'),
                          SelectTextEntry.name(id: 'e', name: 'Center'),
                        },
                      ),
                    },
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
                    entries: {
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
                    sideBarTheme: const SelectSideBarTheme(width: 100),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
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
                    entries: {
                      SelectRangeEntry.custom(),
                      SelectTextEntry.name(id: 'a', name: '0-100'),
                      SelectTextEntry.name(id: 'b', name: '100-500'),
                      SelectTextEntry.name(id: 'c', name: '500-1000'),
                      SelectTextEntry.name(id: 'd', name: '1000-2000'),
                    },
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    selectionMode: SelectionMode.multiple,
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
                    entries: {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '0-100'),
                          SelectTextEntry.name(id: 'b', name: '100-500'),
                          SelectTextEntry.name(id: 'c', name: '500-1000'),
                          SelectTextEntry.name(id: 'd', name: '1000-2000'),
                          SelectRangeEntry.custom(),
                        },
                        selectionMode: SelectionMode.single,
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
                          SelectTextEntry.name(id: 'a', name: 'Football'),
                          SelectTextEntry.name(id: 'b', name: 'Basketball'),
                          SelectTextEntry.name(id: 'c', name: 'Baseball'),
                          SelectTextEntry.name(id: 'd', name: 'Tennis'),
                        },
                        selectionMode: SelectionMode.single,
                        footer: SelectTextEntry.children(
                          id: 'c3-f',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'f-a', name: 'A'),
                            SelectTextEntry.name(id: 'f-b', name: 'B'),
                            SelectTextEntry.name(id: 'f-c', name: 'C'),
                            SelectTextEntry.name(id: 'f-d', name: 'D'),
                          },
                        ),
                        footerSelectionMode: SelectionMode.single,
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        header: SelectTextEntry.children(
                          id: 'c4-h',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'h-a', name: 'A'),
                            SelectTextEntry.name(id: 'h-b', name: 'B'),
                            SelectTextEntry.name(id: 'h-c', name: 'C'),
                            SelectTextEntry.name(id: 'h-d', name: 'D'),
                          },
                        ),
                        headerSelectionMode: SelectionMode.single,
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Mathematics'),
                          SelectTextEntry.name(id: 'b', name: 'Language'),
                          SelectTextEntry.name(id: 'c', name: 'Science'),
                          SelectTextEntry.name(id: 'd', name: 'History'),
                        },
                        selectionMode: SelectionMode.single,
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
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
                        id: 'cate6',
                        name: 'Cate 6',
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
                    entries: {
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
                    entries: {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '0-100'),
                          SelectTextEntry.name(id: 'b', name: '100-500'),
                          SelectTextEntry.name(id: 'c', name: '500-1000'),
                          SelectTextEntry.name(id: 'd', name: '1000-2000'),
                          SelectRangeEntry.custom(),
                        },
                        selectionMode: SelectionMode.single,
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
                        header: SelectTextEntry.children(
                          id: 'c3-h',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'h-a', name: 'A'),
                            SelectTextEntry.name(id: 'h-b', name: 'B'),
                            SelectTextEntry.name(id: 'h-c', name: 'C'),
                            SelectTextEntry.name(id: 'h-d', name: 'D'),
                          },
                        ),
                        headerSelectionMode: SelectionMode.single,
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Football'),
                          SelectTextEntry.name(id: 'b', name: 'Basketball'),
                          SelectTextEntry.name(id: 'c', name: 'Baseball'),
                          SelectTextEntry.name(id: 'd', name: 'Tennis'),
                        },
                        selectionMode: SelectionMode.single,
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Mathematics'),
                          SelectTextEntry.name(id: 'b', name: 'Language'),
                          SelectTextEntry.name(id: 'c', name: 'Science'),
                          SelectTextEntry.name(id: 'd', name: 'History'),
                        },
                        selectionMode: SelectionMode.single,
                        footer: SelectTextEntry.children(
                          id: 'c4-f',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'f-a', name: 'A'),
                            SelectTextEntry.name(id: 'f-b', name: 'B'),
                            SelectTextEntry.name(id: 'f-c', name: 'C'),
                            SelectTextEntry.name(id: 'f-d', name: 'D'),
                          },
                        ),
                        footerSelectionMode: SelectionMode.single,
                        layout: const SelectGridLayout(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
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
                        id: 'cate6',
                        name: 'Cate 6',
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
                    entries: {
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
                    entries: {
                      SelectCategoryEntry.children(
                        id: 'cate1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '0-100'),
                          SelectTextEntry.name(id: 'b', name: '100-500'),
                          SelectTextEntry.name(id: 'c', name: '500-1000'),
                          SelectTextEntry.name(id: 'd', name: '1000-2000'),
                          SelectRangeEntry.custom(),
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
                        },
                        selectionMode: SelectionMode.multiple,
                        layout: const SelectChipLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate3',
                        name: 'Cate 3',
                        header: SelectTextEntry.children(
                          id: 'c3-h',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'h-a', name: 'A'),
                            SelectTextEntry.name(id: 'h-b', name: 'B'),
                            SelectTextEntry.name(id: 'h-c', name: 'C'),
                            SelectTextEntry.name(id: 'h-d', name: 'D'),
                          },
                        ),
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Football'),
                          SelectTextEntry.name(id: 'b', name: 'Basketball'),
                          SelectTextEntry.name(id: 'c', name: 'Baseball'),
                          SelectTextEntry.name(id: 'd', name: 'Tennis'),
                        },
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate4',
                        name: 'Cate 4',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Mathematics'),
                          SelectTextEntry.name(id: 'b', name: 'Language'),
                          SelectTextEntry.name(id: 'c', name: 'Science'),
                          SelectTextEntry.name(id: 'd', name: 'History'),
                        },
                        footer: SelectTextEntry.children(
                          id: 'c4-f',
                          name: 'Letter Grade',
                          children: {
                            SelectTextEntry.name(id: 'f-a', name: 'A'),
                            SelectTextEntry.name(id: 'f-b', name: 'B'),
                            SelectTextEntry.name(id: 'f-c', name: 'C'),
                            SelectTextEntry.name(id: 'f-d', name: 'D'),
                          },
                        ),
                        layout: const SelectGridLayout(
                          crossAxisCount: 3,
                          childAspectRatio: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'cate5',
                        name: 'Cate 5',
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
                        id: 'cate6',
                        name: 'Cate 6',
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
