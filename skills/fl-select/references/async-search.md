# Async loading, search, and serialization

## entriesLoader — async-first

Every delegate loads data through `entriesLoader`, a `Future<SelectEntries> Function()` where `SelectEntries` is `Set<SelectEntry>`:

```dart
Future<SelectEntries> _fetchNeighborhood() async {
  final dto = await api.getNeighborhoods();
  return {
    SelectCategoryEntry(
      id: 'region',
      name: dto.regionName,
      children: {
        for (final n in dto.neighborhoods)
          SelectTextEntry(parentId: 'region', id: n.id, name: n.name, extra: n),
      },
    ),
  };
}
```

## Loading and error states

- `skeletonBuilder`: replaces the default skeletons while entries load.
- `errorBuilder`: renders a fallback when `entriesLoader` throws.

```dart
CascadingSelectDelegate(
  entriesLoader: _fetchNeighborhood,
  errorBuilder: (context, error, stackTrace, reload) => ErrorRetry(reload: reload),
);
```

Style the default skeletons via `delegate.skeletonTheme`.

## Initial selection (async restore)

```dart
GridSelectDelegate(
  crossAxisCount: 3,
  entriesLoader: _fetchPrice,
  selectedEntriesLoader: () async => loadSavedSelection(), // Future<SelectEntries?> — null = none
  resetEntriesLoader: () async => loadDefaultSelection(),  // restored after "Reset"
)
```

## Search

Set `searchEnabled: true` on any delegate to render a `SelectSearchBar` above the body:

```dart
CascadingSelectDelegate(
  entriesLoader: _fetchNeighborhood,
  searchEnabled: true,
  searchHintText: 'Search',
  searchDebounceDuration: const Duration(milliseconds: 300),
  searchPredicate: (entry, query) =>
      entry.name.toLowerCase().contains(query.toLowerCase()),
);
```

Behavior: typing filters the displayed entries (debounced, default 300 ms) while preserving layout and selection state; canceling the search restores the original entries. The default predicate is `defaultSelectSearchPredicate` — a case-insensitive substring match on `SelectEntry.name`. Provide a custom `searchPredicate` to match `id`, `extra`, or other fields. Style the bar with `delegate.searchBarTheme` or globally via `SelectThemeData`.

## Serializing selections

Selections arrive as a `SelectEntries` tree. Two extensions convert it into URL query parameters — each category contributes key/value pairs keyed by its own id, with the deepest selected leaf ids as values; an "Any" leaf resolves to its parent id; a custom `SelectRangeEntry` formats as `min-max`:

```dart
final selected = await showSelect(context: context, delegate: ...);

// Map<String, List<String>> — mirrors Uri.queryParametersAll
selected?.toQueryMap(); // {price: [0-100], more: [near_subway]}

// Ready-made query string
selected?.toQueryParameters(); // price=0-100&more=near_subway

// Multi-value formats via SelectArrayFormat
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.brackets);  // more[]=a&more[]=b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.comma);     // more=a,b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.indices);   // more[0]=a
selected?.toQueryParameters(
  arrayFormat: SelectArrayFormat.delimited,
  delimiter: '|',
); // more=a|b — covers OpenAPI pipeDelimited / spaceDelimited
```

Values are percent-encoded by default; pass `encode: false` when the caller handles encoding.
