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
              PopupTab(label: 'Wrap'),
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
              ),
              TabNavSelectDelegate(
                entries: multiCategoryData,
              ),
              SideNavSelectDelegate(
                entries: multiCategoryData,
              ),
              ExpandableSelectDelegate(
                entries: multiCategoryData,
              ),
            ],
            onApplied: (tabData, selected) {
              largePrint('onApplied: $tabData, $selected');
            },
          ),
        ],
      ),
    );
  }
}
