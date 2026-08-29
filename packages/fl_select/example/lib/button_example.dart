import 'package:example/entry_data.dart';
import 'package:example/log.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class PopupSelectButtonExample extends StatefulWidget {
  const PopupSelectButtonExample({super.key});

  @override
  State<PopupSelectButtonExample> createState() =>
      _PopupSelectButtonExampleState();
}

class _PopupSelectButtonExampleState extends State<PopupSelectButtonExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupSelectButton')),
      body: Center(
        child: Column(
          children: [
            PopupSelectButton(
              label: 'PopupSelectButton',
              selectDelegate: ListSelectDelegate(
                entries: listData,
              ),
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                largePrint('toQueryMap: ${selected.toQueryMap()}');
                largePrint(
                    'toQueryParameters: ${selected.toQueryParameters()}');
              },
            ),
            SizedBox(height: 24),
            PopupSelectButton.elevated(
              label: 'PopupSelectButton',
              selectDelegate: GridSelectDelegate(
                entries: gridData,
                crossAxisCount: 3,
                childAspectRatio: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              onApplied: (selected) {
                largePrint('onApplied: $selected');
              },
            ),
            SizedBox(height: 24),
            PopupSelectButton.filled(
              label: 'PopupSelectButton',
              selectDelegate: WrapSelectDelegate(
                entries: wrapData,
              ),
              onApplied: (selected) {
                largePrint('onApplied: $selected');
              },
            ),
            SizedBox(height: 24),
            PopupSelectButton.outlined(
              label: 'PopupSelectButton',
              selectDelegate: CascadingSelectDelegate(
                entriesLoader: fetchCascadingData,
                selectionMode: SelectionMode.multiple,
              ),
              onApplied: (selected) {
                largePrint('onApplied: $selected');
              },
            ),
          ],
        ),
      ),
    );
  }
}
