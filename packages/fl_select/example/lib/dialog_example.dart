import 'package:example/entry_data.dart';
import 'package:example/log.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class DialogExample extends StatefulWidget {
  const DialogExample({super.key});

  @override
  State<DialogExample> createState() => _DialogExampleState();
}

class _DialogExampleState extends State<DialogExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: ListSelectDelegate(
                        entries: listData,
                      ),
                      leading: Icon(Icons.list),
                      title: Text('ListSelect'),
                    );
                    largePrint('result: $result');
                    largePrint('toQueryMap: ${result?.toQueryMap()}');
                    largePrint(
                        'toQueryParameters: ${result?.toQueryParameters()}');
                  },
                  child: const Text('showListSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: GridSelectDelegate(
                        entries: gridData,
                        crossAxisCount: 3,
                        childAspectRatio: 2.4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      title: Text('GridSelect'),
                      trailing: CloseButton(),
                      centerTitle: false,
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showGridSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: WrapSelectDelegate(
                        entries: wrapData,
                        selectionMode: SelectionMode.multiple,
                        spacing: 12.0,
                        runSpacing: 12.0,
                      ),
                      leading: Icon(Icons.list),
                      title: Text('ListSelect'),
                      trailing: CloseButton(),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showWrapSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: CascadingSelectDelegate(
                        entriesLoader: fetchCascadingData,
                        selectionMode: SelectionMode.multiple,
                        sideBarTheme: const SelectSideBarTheme(width: 120),
                        isScrollable: true,
                      ),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showCascadingSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: TabNavSelectDelegate(
                        defaultLayout: SelectGridLayout(
                          crossAxisCount: 2,
                          childAspectRatio: 3.6,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        entries: multiCategoryData,
                        selectionMode: SelectionMode.multiple,
                        isScrollable: true,
                      ),
                      title: Text('TabNavSelect'),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showTabNavSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: SideNavSelectDelegate(
                        defaultLayout: SelectWrapLayout(
                          spacing: 12,
                          runSpacing: 12,
                        ),
                        entries: multiCategoryData,
                        selectionMode: SelectionMode.multiple,
                      ),
                      title: Text('SideNavSelect'),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showSideNavSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showSelect(
                      context: context,
                      delegate: ExpandableSelectDelegate(
                        defaultLayout: SelectListLayout(),
                        entries: multiCategoryData,
                        selectionMode: SelectionMode.multiple,
                      ),
                      title: Text('ExpandableSelect'),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showExpandableSelect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
