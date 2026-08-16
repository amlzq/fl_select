// ignore_for_file: avoid_print

import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';

class DialogBottomSheetDemoPage extends StatefulWidget {
  const DialogBottomSheetDemoPage({super.key});

  @override
  State<DialogBottomSheetDemoPage> createState() =>
      _DialogBottomSheetDemoPageState();
}

class _DialogBottomSheetDemoPageState extends State<DialogBottomSheetDemoPage> {
  late final HouseFiltersRepository _filtersRepo;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog & BottomSheet')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dialog'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showSelect(
                  context: context,
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchNeighborhoodData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchNeighborhoodSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchNeighborhoodResetData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 150),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  title: const Text('Neighborhood'),
                );
                if (result == null) return;
                _filtersRepo.neighborhoodResult = result;
                if (context.mounted) showSelectResult(context, result);
                final first = result.firstSelectedId;
                if (first != null) {
                  largePrint(
                      'neighborhood cascading: ${result.cascadingPairsOf(first)}');
                }
              },
              child: const Text('Show Neighborhood Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showSelect(
                  context: context,
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchPriceData,
                    selectedEntriesLoader: _filtersRepo.fetchPriceSelectedData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                  ),
                  title: const Text('Price'),
                  centerTitle: false,
                );
                if (result == null) return;
                _filtersRepo.priceResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('price first: ${result.firstSelectedId}');
                largePrint(
                    'price list ranges: ${result.childRangesOf('list_price')}');
                largePrint(
                    'price monthly ranges: ${result.childRangesOf('monthly_price')}');
              },
              child: const Text('Show Price Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRoomsData,
                    selectedEntriesLoader: _filtersRepo.fetchRoomsSelectedData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                    panelTheme: const SelectPanelTheme(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                  title: const Text('Rooms'),
                  leading: const Icon(Icons.room),
                );
                if (result == null) return;
                _filtersRepo.roomsResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show Rooms Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchMoreData,
                    selectedEntriesLoader: _filtersRepo.fetchMoreSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchMoreResetData,
                    selectionMode: SelectionMode.multiple,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                    chipBarTheme: const SelectChipBarTheme(
                      variant: SelectChipVariant.outlined,
                    ),
                  ),
                  elevation: 12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  title: const Text('More'),
                  trailing: CloseButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                );
                if (result == null) return;
                _filtersRepo.moreResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show More Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortData,
                    selectedEntriesLoader: _filtersRepo.fetchSortSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    panelTheme: const SelectPanelTheme(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                  elevation: 12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  title: const Text('Sort'),
                  leading: const Icon(Icons.sort),
                  trailing: CloseButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                );

                if (result == null) return;
                _filtersRepo.sortResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('sort id: ${result.firstSelectedId}');
              },
              child: const Text('Show Sort Select'),
            ),
            const SizedBox(height: 16),
            const Text('BottomSheet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showModalBottomSelect(
                  context: context,
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchNeighborhoodData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchNeighborhoodSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchNeighborhoodResetData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 150),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  title: const Text('Neighborhood'),
                );
                if (result == null) return;
                _filtersRepo.neighborhoodResult = result;
                if (context.mounted) showSelectResult(context, result);
                final first = result.firstSelectedId;
                if (first != null) {
                  largePrint(
                      'neighborhood cascading: ${result.cascadingPairsOf(first)}');
                }
              },
              child: const Text('Show Neighborhood Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showModalBottomSelect(
                  context: context,
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchPriceData,
                    selectedEntriesLoader: _filtersRepo.fetchPriceSelectedData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 4,
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                  ),
                  title: const Text('Price'),
                  centerTitle: false,
                );
                if (result == null) return;
                _filtersRepo.priceResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('price first: ${result.firstSelectedId}');
                largePrint(
                    'price list ranges: ${result.childRangesOf('list_price')}');
                largePrint(
                    'price monthly ranges: ${result.childRangesOf('monthly_price')}');
              },
              child: const Text('Show Price Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showModalBottomSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRoomsData,
                    selectedEntriesLoader: _filtersRepo.fetchRoomsSelectedData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  elevation: 12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  title: const Text('Rooms'),
                  leading: const Icon(Icons.room),
                );
                if (result == null) return;
                _filtersRepo.roomsResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show Rooms Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showModalBottomSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchMoreData,
                    selectedEntriesLoader: _filtersRepo.fetchMoreSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchMoreResetData,
                    selectionMode: SelectionMode.multiple,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                    chipBarTheme: const SelectChipBarTheme(
                      variant: SelectChipVariant.outlined,
                    ),
                  ),
                  title: const Text('More'),
                  trailing: CloseButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                );
                if (result == null) return;
                _filtersRepo.moreResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show More Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final SelectEntries? result = await showModalBottomSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortData,
                    selectedEntriesLoader: _filtersRepo.fetchSortSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                  ),
                  title: const Text('Sort'),
                  leading: const Icon(Icons.sort),
                  trailing: CloseButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                );
                if (result == null) return;
                _filtersRepo.sortResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('sort id: ${result.firstSelectedId}');
              },
              child: const Text('Show Sort Select'),
            ),
          ],
        ),
      ),
    );
  }
}
