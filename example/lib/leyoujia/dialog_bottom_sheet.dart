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
                final result = await showSelect(
                  context: context,
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRegionData,
                    selectedEntriesLoader: _filtersRepo.fetchRegionResetData,
                    resetEntriesLoader: _filtersRepo.fetchRegionResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  title: const Text('区域选择器'),
                );
                // `result` is a bare `SelectEntries?` (the return type of
                // showSelect). The query helpers now live on
                // `SelectEntriesExtension`, so they can be called directly.
                if (result == null) return;
                _filtersRepo.regionResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('region first: ${result.firstSelectedId}');
                final regionFirst = result.firstSelectedId;
                if (regionFirst != null) {
                  largePrint(
                      'region cascading: ${result.cascadingPairsOf(regionFirst)}');
                }
              },
              child: const Text('Show Region Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showSelect(
                  context: context,
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchBuyPriceData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchBuyPriceSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchBuyPriceResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
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
                  title: const Text('价格选择器'),
                );
                if (result == null) return;
                _filtersRepo.buyPriceResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('price first: ${result.firstSelectedId}');
                largePrint(
                    'price total ranges: ${result.childRangesOf('total')}');
                largePrint(
                    'price unit ranges: ${result.childRangesOf('unit')}');
              },
              child: const Text('Show Price Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchFloorPlanBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchFloorPlanBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchFloorPlanBuyResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 2,
                    childAspectRatio: 3.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                    panelTheme: const SelectPanelTheme(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                  title: const Text('户型选择器'),
                );
                if (result == null) return;
                _filtersRepo.floorPlanBuyResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show FloorPlan Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchMoreBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchMoreBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchMoreBuyResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 2,
                    childAspectRatio: 3.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 98),
                  ),
                  elevation: 12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  title: const Text('更多选择器'),
                );
                if (result == null) return;
                _filtersRepo.moreBuyResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show More Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchSortBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
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
                  title: const Text('排序选择器'),
                );
                if (result == null) return;
                _filtersRepo.sortBuyResult = result;
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
                final result = await showModalBottomSelect(
                  context: context,
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRegionData,
                    selectedEntriesLoader: _filtersRepo.fetchRegionResetData,
                    resetEntriesLoader: _filtersRepo.fetchRegionResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  title: const Text('区域选择器'),
                );
                if (result == null) return;
                _filtersRepo.regionResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('region first: ${result.firstSelectedId}');
                final regionFirst = result.firstSelectedId;
                if (regionFirst != null) {
                  largePrint(
                      'region cascading: ${result.cascadingPairsOf(regionFirst)}');
                }
              },
              child: const Text('Show Region Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSelect(
                  context: context,
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchBuyPriceData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchBuyPriceSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchBuyPriceResetData,
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
                  title: const Text('价格选择器'),
                );
                if (result == null) return;
                _filtersRepo.buyPriceResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('price first: ${result.firstSelectedId}');
                largePrint(
                    'price total ranges: ${result.childRangesOf('total')}');
                largePrint(
                    'price unit ranges: ${result.childRangesOf('unit')}');
              },
              child: const Text('Show Price Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchFloorPlanBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchFloorPlanBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchFloorPlanBuyResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  elevation: 12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  title: const Text('户型选择器'),
                );
                if (result == null) return;
                _filtersRepo.floorPlanBuyResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show FloorPlan Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSelect(
                  context: context,
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchMoreBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchMoreBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchMoreBuyResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 98),
                    panelTheme: const SelectPanelTheme(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                  title: const Text('更多选择器'),
                );
                if (result == null) return;
                _filtersRepo.moreBuyResult = result;
                if (context.mounted) showSelectResult(context, result);
                largePrint('result: $result');
              },
              child: const Text('Show More Select'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSelect(
                  context: context,
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchSortBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                  ),
                  title: const Text('排序选择器'),
                );
                if (result == null) return;
                _filtersRepo.sortBuyResult = result;
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
