import 'package:example/entry_data.dart';
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
      body: Column(
        children: [
          PopupSelectBar(
            isScrollable: true,
            tabs: const [
              PopupTab(label: 'List'),
              PopupTab(label: 'Grid'),
              PopupTab(child: Icon(Icons.wrap_text)),
              PopupTab(label: 'Cascading'),
              PopupTab(label: 'TabNav'),
              PopupTab(label: 'SideNav'),
              PopupTab(child: Icon(Icons.expand)),
            ],
            selectDelegates: [
              ListSelectDelegate(
                entries: listData,
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
              ),
              CascadingSelectDelegate(
                entriesLoader: fetchCascadingData,
                selectionMode: SelectionMode.multiple,
                sideBarTheme: const SelectSideBarTheme(width: 120),
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
              ),
              SideNavSelectDelegate(
                defaultLayout: SelectGridLayout(
                  crossAxisCount: 2,
                  childAspectRatio: 3.8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                entries: multiCategoryData,
                selectionMode: SelectionMode.multiple,
              ),
              ExpandableSelectDelegate(
                entries: multiCategoryData,
                selectionMode: SelectionMode.multiple,
              ),
            ],
            onApplied: (tabData, selected) {
              largePrint('onApplied: $tabData, $selected');
              largePrint('toQueryMap: ${selected.toQueryMap()}');
              largePrint('toQueryParameters: ${selected.toQueryParameters()}');
            },
          ),
        ],
      ),
    );
  }
}
