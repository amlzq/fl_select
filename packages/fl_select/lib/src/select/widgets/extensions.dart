import 'package:material_ui/material_ui.dart';

extension ChildrenExtension on List<Widget> {
  List<Widget> separateWith(Widget separator) {
    if (isEmpty) return [];
    return [
      first,
      ...sublist(1).expand((widget) => [separator, widget]),
    ];
  }
}
