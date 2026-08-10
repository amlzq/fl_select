import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  @override
  void dispose() {
    super.dispose();
  }

  HouseFilter? _parseFilter(String domain, SelectEntries selected) {
    final filter = HouseFilter(cityId: userCityId);
    if (domain == 'neighborhood') {
      // Neighborhood filter
      filter.neighborhood = selected
          .cascadingPairsOf('neighborhood')
          .map((p) => {
                "region_id": p.id,
                "neighborhood_id": p.childIds,
              })
          .toList(growable: false);
    } else if (domain == 'price') {
      // Price filter
      final category = selected.firstOrNull;
      if (category == null) return null;
      if (category.id == 'list_price') {
        filter.listPrice = selected
            .childRangesOf('list_price')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      } else if (category.id == 'monthly_price') {
        filter.monthlyPayment = selected
            .childRangesOf('monthly_price')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      }
    } else if (domain == 'rooms') {
      // Rooms filter
      filter.bedrooms = selected.childIdsOf('bedrooms');
      filter.bathrooms = selected.childIdsOf('bathrooms');
    } else if (domain == 'more') {
      // More filter
      filter.homeType = selected.childIdsOf('home_type');
      filter.listsDetails = selected.childIdsOf('lists_details');
      filter.squareFeet = selected.childIdsOf('square_feet');
      filter.lotSize = selected.childIdsOf('lot_size');
      filter.homeFeatures = selected.childIdsOf('home_features');
      filter.commute = selected.childIdsOf('commute');
      filter.expandedSearch = selected.childIdsOf('expanded_search');
    } else if (domain == 'sort') {
      // Sort filter
      filter.sort = selected.firstSelectedId;
    }
    return filter;
  }

  void _handleSelectChange(String domain, SelectEntries selected) async {
    final l10n = AppLocalizations.of(context);
    _filter = _parseFilter(domain, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  void _handleSelectApply(String domain, SelectEntries selected) {
    final l10n = AppLocalizations.of(context);
    // Persist the applied selection to the repo so it can be restored on reopen.
    if (domain == 'neighborhood') {
      _filtersRepo.neighborhoodResult = selected;
    } else if (domain == 'price') {
      _filtersRepo.priceResult = selected;
    } else if (domain == 'rooms') {
      _filtersRepo.roomsResult = selected;
    } else if (domain == 'more') {
      _filtersRepo.moreResult = selected;
    } else if (domain == 'sort') {
      _filtersRepo.sortResult = selected;
    }
    _filter = _parseFilter(domain, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupSelectButton')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          PopupSelectButton(
            label: 'Neighborhood',
            selectDelegate: CascadingSelectDelegate(
              entriesLoader: _filtersRepo.fetchNeighborhoodData,
              selectedEntriesLoader: _filtersRepo.fetchNeighborhoodSelectedData,
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
              largePrint('onChanged: $selected');
              _handleSelectChange('neighborhood', selected);
              showSelectResult(context, selected);
            },
            onApplied: (selected) {
              largePrint('onApplied: $selected');
              _handleSelectApply('neighborhood', selected);
              showSelectResult(context, selected);
            },
            onReset: () {
              debugPrint('onReset');
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupSelectButton.elevated(
              label: 'Price',
              selectDelegate: GridSelectDelegate(
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
                applyText: AppLocalizations.of(context)?.apply ?? '',
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('price', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('price', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: PopupSelectButton.outlined(
              label: 'Rooms',
              selectDelegate: FlattenSelectDelegate(
                entriesLoader: _filtersRepo.fetchRoomsData,
                selectedEntriesLoader: _filtersRepo.fetchRoomsSelectedData,
                selectionMode: SelectionMode.multiple,
                sideBarTheme: const SelectSideBarTheme(width: 98),
                panelTheme: const SelectPanelTheme(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('rooms', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('rooms', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 50),
              child: PopupSelectButton(
                label: 'More',
                icon: const Icon(Icons.filter_alt_outlined),
                selectDelegate: ListSelectDelegate(
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
                onChanged: (selected) {
                  largePrint('onChanged: $selected');
                  _handleSelectChange('more', selected);
                  showSelectResult(context, selected);
                },
                onApplied: (selected) {
                  largePrint('onApplied: $selected');
                  _handleSelectApply('more', selected);
                  showSelectResult(context, selected);
                },
                onReset: () {
                  debugPrint('onReset');
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: PopupSelectButton(
              label: 'Sort',
              icon: const Icon(Icons.filter_alt_outlined),
              selectDelegate: ListSelectDelegate(
                entriesLoader: _filtersRepo.fetchSortData,
                selectedEntriesLoader: _filtersRepo.fetchSortSelectedData,
                resetEntriesLoader: _filtersRepo.fetchSortResetData,
                selectionMode: SelectionMode.single,
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('sort', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('sort', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
        ],
      ),
    );
  }
}
