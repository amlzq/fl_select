import 'package:example/entry_repository.dart';
import 'package:example/log.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class BottomSheetExample extends StatefulWidget {
  const BottomSheetExample({super.key});

  @override
  State<BottomSheetExample> createState() => _BottomSheetExampleState();
}

class _BottomSheetExampleState extends State<BottomSheetExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BottomSheet')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
                      context: context,
                      delegate: ListSelectDelegate(
                        entries: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                      ),
                      leading: Icon(Icons.list),
                      title: Text('ListSelect'),
                    );
                    largePrint('result: $result');
                    largePrint('toQueryMap: ${result?.toQueryMap()}');
                    largePrint(
                        'toQueryParameters: ${result?.toQueryParameters()}');
                  },
                  child: const Text('showModalBottomListSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
                      context: context,
                      delegate: GridSelectDelegate(
                        entries: gridData,
                        crossAxisCount: 3,
                        childAspectRatio: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      title: Text('GridSelect'),
                      centerTitle: false,
                      trailing: CloseButton(),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showModalBottomGridSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
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
                  child: const Text('showModalBottomWrapSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
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
                  child: const Text('showModalBottomCascadingSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
                      context: context,
                      delegate: TabNavSelectDelegate(
                        defaultLayout: SelectGridLayout(
                          crossAxisCount: 3,
                          childAspectRatio: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        entries: multiCategoryData,
                        selectionMode: SelectionMode.multiple,
                      ),
                      title: Text('TabNavSelect'),
                    );
                    largePrint('result: $result');
                  },
                  child: const Text('showModalBottomTabNavSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
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
                  child: const Text('showModalBottomSideNavSelect'),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSelect(
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
                  child: const Text('showModalBottomExpandableSelect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
