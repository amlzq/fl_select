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
        child: PopupSelectButton(
          label: 'PopupSelectButton',
          selectDelegate: ListSelectDelegate(
            entries: {
              SelectTextEntry.name(id: 'a', name: 'A'),
              SelectTextEntry.name(id: 'b', name: 'B'),
              SelectTextEntry.name(id: 'c', name: 'C'),
              SelectTextEntry.name(id: 'd', name: 'D'),
            },
          ),
          onApplied: (selected) {
            largePrint('onApplied: $selected');
          },
        ),
      ),
    );
  }
}
