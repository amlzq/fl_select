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
      body: Center(
        child: PopupSelectBar(
          tabs: const [
            PopupTab(label: ''),
            PopupTab(label: ''),
            PopupTab(label: ''),
            PopupTab(child: Icon(Icons.sort))
          ],
          selectDelegates: [
            CascadingSelectDelegate(
              entries: {
                SelectTextEntry.name(id: 'a', name: 'A'),
                SelectTextEntry.name(id: 'b', name: 'B'),
                SelectTextEntry.name(id: 'c', name: 'C'),
                SelectTextEntry.name(id: 'd', name: 'D'),
              },
            ),
            ListSelectDelegate(
              entries: {
                SelectTextEntry.name(id: 'a', name: 'A'),
                SelectTextEntry.name(id: 'b', name: 'B'),
                SelectTextEntry.name(id: 'c', name: 'C'),
                SelectTextEntry.name(id: 'd', name: 'D'),
              },
            ),
            GridSelectDelegate(
              entries: {
                SelectTextEntry.name(id: 'a', name: 'A'),
                SelectTextEntry.name(id: 'b', name: 'B'),
                SelectTextEntry.name(id: 'c', name: 'C'),
                SelectTextEntry.name(id: 'd', name: 'D'),
              },
              crossAxisCount: 3,
              childAspectRatio: 3.2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            WrapSelectDelegate(
              entries: {
                SelectTextEntry.name(id: 'a', name: 'A'),
                SelectTextEntry.name(id: 'b', name: 'B'),
                SelectTextEntry.name(id: 'c', name: 'C'),
                SelectTextEntry.name(id: 'd', name: 'D'),
              },
            ),
          ],
          onApplied: (tabData, selected) {
            largePrint('onApplied: $tabData, $selected');
          },
        ),
      ),
    );
  }
}
