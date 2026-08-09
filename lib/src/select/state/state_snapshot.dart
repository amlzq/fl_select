import '../select_entry.dart';

class StateSnapshot {
  const StateSnapshot({
    required this.selectedEntriesPerLevel,
    required this.selectedHeaderEntries,
    required this.selectedFooterEntries,
  });

  final List<SelectEntries> selectedEntriesPerLevel;
  final Map<String, SelectEntries> selectedHeaderEntries;
  final Map<String, SelectEntries> selectedFooterEntries;
}
