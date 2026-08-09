import 'package:flutter/material.dart';

class SelectBadge extends StatelessWidget {
  const SelectBadge({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
