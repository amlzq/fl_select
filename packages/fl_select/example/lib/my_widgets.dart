import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

class MyRadio extends StatelessWidget {
  final bool value;

  const MyRadio({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value) {
      return Icon(Icons.check,
          size: 14, color: Theme.of(context).colorScheme.primary);
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
      child:
          value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}

class MyListItem extends StatelessWidget {
  const MyListItem({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final SelectEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: Row(
          children: [
            Text(entry.name ?? ''),
            Spacer(),
            if (selected) const Icon(Icons.check),
          ],
        ),
      ),
    );
  }
}

class MyGridItem extends StatelessWidget {
  const MyGridItem({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final SelectEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Text(entry.name ?? ''),
          ),
          if (selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: const Icon(Icons.check),
            )
        ],
      ),
    );
  }
}

class MyWrapItem extends StatelessWidget {
  const MyWrapItem({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final SelectEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          color:
              selected ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
        child: Text(entry.name ?? ''),
      ),
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
