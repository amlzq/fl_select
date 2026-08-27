import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class MyRadio extends StatelessWidget {
  final bool value;

  const MyRadio({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value) {
      return Icon(
        Icons.check,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class MyCheckbox extends StatelessWidget {
  final bool value;

  const MyCheckbox({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final effectiveCheckColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? effectiveCheckColor : Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
        color: value ? effectiveCheckColor : Colors.transparent,
      ),
      child: value
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class MyActionBar extends StatelessWidget {
  const MyActionBar({
    super.key,
    required this.applyTextVN,
    required this.onResetTap,
    required this.onApplyTap,
  });

  final ValueNotifier<String> applyTextVN;

  final VoidCallback onResetTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    // final SelectController? controller = SelectController.of(context)!;
    return ValueListenableBuilder<String>(
      valueListenable: applyTextVN,
      builder: (context, applyText, _) {
        return SelectActionBar(
          applyText: applyText,
          onResetTap: onResetTap,
          onApplyTap: onApplyTap,
        );
      },
    );
  }
}
