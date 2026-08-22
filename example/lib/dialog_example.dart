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
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showSelect(
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
            child: const Text('AlertDialog'),
          ),
        ],
      ),
    );
  }
}
