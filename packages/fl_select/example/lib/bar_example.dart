import 'package:example/entry_repository.dart';
import 'package:example/log.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class PopupSelectBarExample extends StatefulWidget {
  const PopupSelectBarExample({super.key});

  @override
  State<PopupSelectBarExample> createState() => _PopupSelectBarExampleState();
}

class _PopupSelectBarExampleState extends State<PopupSelectBarExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupSelectBar')),
      body: SafeArea(
        child: Column(
          children: [
            PopupSelectBar(
              isScrollable: true,
              tabs: [
                PopupTab(
                  label: 'List',
                  labelLoader: (selected) => '${selected.length} selected',
                ),
                PopupTab(label: 'Grid'),
                PopupTab(child: Icon(Icons.wrap_text)),
                PopupTab(label: 'Cascading'),
                PopupTab(
                  label: 'TabNav',
                  labelLoader: (selected) => '${selected.length} selected',
                ),
                PopupTab(label: 'SideNav'),
                PopupTab(child: Icon(Icons.expand)),
              ],
              selectDelegates: [
                ListSelectDelegate(
                  entries: listData,
                  searchEnabled: true,
                  searchPredicate: (entry, query) {
                    return entry.name?.contains(query) == true;
                  },
                ),
                GridSelectDelegate(
                  entries: gridData,
                  crossAxisCount: 3,
                  childAspectRatio: 3.2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                WrapSelectDelegate(
                  entries: wrapData,
                  selectionMode: SelectionMode.multiple,
                  spacing: 12.0,
                  runSpacing: 12.0,
                ),
                CascadingSelectDelegate(
                  entriesLoader: fetchCascadingData,
                  selectionMode: SelectionMode.multiple,
                  sideBarTheme: const SelectSideBarTheme(width: 120),
                  searchEnabled: true,
                  searchPredicate: (entry, query) {
                    return entry.name?.contains(query) == true;
                  },
                ),
                TabNavSelectDelegate(
                  defaultLayout: SelectGridLayout(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  entries: multiCategoryData,
                  selectionMode: SelectionMode.multiple,
                  searchEnabled: true,
                  searchPredicate: (entry, query) {
                    return entry.name?.contains(query) == true;
                  },
                ),
                SideNavSelectDelegate(
                  defaultLayout: SelectWrapLayout(
                    spacing: 12,
                    runSpacing: 12,
                  ),
                  entries: multiCategoryData,
                  selectionMode: SelectionMode.multiple,
                  searchEnabled: true,
                  searchPredicate: (entry, query) {
                    return entry.name?.contains(query) == true;
                  },
                ),
                ExpandableSelectDelegate(
                  defaultLayout: SelectListLayout(),
                  entries: multiCategoryData,
                  selectionMode: SelectionMode.multiple,
                  searchEnabled: true,
                  searchPredicate: (entry, query) {
                    return entry.name?.contains(query) == true;
                  },
                ),
              ],
              onApplied: (tabData, selected) {
                largePrint('onApplied: $tabData, $selected');
                largePrint('toQueryMap: ${selected.toQueryMap()}');
                largePrint(
                    'toQueryParameters: ${selected.toQueryParameters()}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
