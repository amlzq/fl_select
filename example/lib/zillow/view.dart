import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  void _handleNeighborhoodChange(SelectEntries result) async {
    final l10n = AppLocalizations.of(context);
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.neighborhoodResult = result;
    _filter?.neighborhood = result
        .cascadingPairsOf('neighborhood')
        .map((p) => {
              "region_id": p.id,
              "neighborhood_id": p.childIds,
            })
        .toList(growable: false);

    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  void _handlePriceChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.priceResult = result;
    final category = result.firstOrNull;
    if (category == null) return null;
    if (category.id == 'list_price') {
      _filter?.listPrice = result
          .childRangesOf('list_price')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    } else if (category.id == 'monthly_price') {
      _filter?.monthlyPayment = result
          .childRangesOf('monthly_price')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    }
  }

  void _handleRoomsChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.roomsResult = result;
    _filter?.bedrooms = result.childIdsOf('bedrooms');
    _filter?.bathrooms = result.childIdsOf('bathrooms');
  }

  void _handleMoreChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.moreResult = result;
    _filter?.homeType = result.childIdsOf('home_type');
    _filter?.listsDetails = result.childIdsOf('lists_details');
    _filter?.squareFeet = result.childIdsOf('square_feet');
    _filter?.lotSize = result.childIdsOf('lot_size');
    _filter?.homeFeatures = result.childIdsOf('home_features');
    _filter?.commute = result.childIdsOf('commute');
    _filter?.expandedSearch = result.childIdsOf('expanded_search');
  }

  void _handleSortChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.sortResult = result;
    _filter?.sort = result.firstSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SelectView')),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Neighborhood',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleNeighborhoodChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Price',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchPriceData,
                    selectedEntriesLoader: _filtersRepo.fetchPriceSelectedData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                    applyText: AppLocalizations.of(context)?.apply ?? '',
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handlePriceChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rooms',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRoomsData,
                    selectedEntriesLoader: _filtersRepo.fetchRoomsSelectedData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 2,
                    childAspectRatio: 3.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 110),
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleRoomsChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'More',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchMoreData,
                    selectedEntriesLoader: _filtersRepo.fetchMoreSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchMoreResetData,
                    selectionMode: SelectionMode.multiple,
                    resetText: AppLocalizations.of(context)?.reset ?? '',
                    applyText: AppLocalizations.of(context)?.apply ?? '',
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleMoreChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sort',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortData,
                    selectedEntriesLoader: _filtersRepo.fetchSortSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleSortChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
