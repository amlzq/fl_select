import 'package:example/entry_data.dart';
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
                  'ListSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entries: listData,
                    searchEnabled: true,
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
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
                  'GridSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entries: gridData,
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    selectionMode: SelectionMode.multiple,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                  ),
                  onChanged: (SelectEntries selected) {
                    largePrint('onChanged: $selected');
                    largePrint('toQueryMap: ${selected.toQueryMap()}');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'WrapSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: WrapSelectDelegate(
                    entries: wrapData,
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
                  'CascadingSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: CascadingSelectDelegate(
                    entriesLoader: fetchCascadingData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 120),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                    searchEnabled: true,
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
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
                  'TabNavSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: TabNavSelectDelegate(
                    defaultLayout: SelectGridLayout(
                      crossAxisCount: 3,
                      childAspectRatio: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    entries: multiCategoryData,
                    selectionMode: SelectionMode.multiple,
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
                  'SideNavSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: SideNavSelectDelegate(
                    entries: multiCategoryData,
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
                  'ExpandableSelectDelegate',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ExpandableSelectDelegate(
                    entries: multiCategoryData,
                    searchEnabled: true,
                    searchPredicate: (entry, query) {
                      return entry.name?.contains(query) == true;
                    },
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
