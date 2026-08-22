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
      appBar: AppBar(
        title: const Text('BottomSheet'),
      ),
      body: Column(
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
            child: const Text('showModalBottomSheet'),
          ),
        ],
      ),
    );
  }
}
