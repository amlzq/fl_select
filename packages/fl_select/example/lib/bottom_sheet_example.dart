import 'package:example/entry_data.dart';
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
      body: Center(
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
                );
                largePrint('result: $result');
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
                  ),
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
                    entries: multiCategoryData,
                  ),
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
                    entries: multiCategoryData,
                  ),
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
                    entries: multiCategoryData,
                  ),
                );
                largePrint('result: $result');
              },
              child: const Text('showModalBottomExpandableSelect'),
            ),
          ],
        ),
      ),
    );
  }
}
