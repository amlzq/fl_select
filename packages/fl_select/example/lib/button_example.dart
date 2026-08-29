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
              label: 'PopupSelectButton.elevated',
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
              label: 'PopupSelectButton.filled',
              selectDelegate: WrapSelectDelegate(
                entries: wrapData,
                spacing: 12.0,
                runSpacing: 12.0,
              ),
              onApplied: (selected) {
                largePrint('onApplied: $selected');
              },
            ),
            SizedBox(height: 24),
            PopupSelectButton.outlined(
              label: 'PopupSelectButton.outlined',
              selectDelegate: CascadingSelectDelegate(
                entriesLoader: fetchCascadingData,
                selectionMode: SelectionMode.multiple,
                sideBarTheme: const SelectSideBarTheme(width: 120),
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
