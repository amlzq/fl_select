/// GenUI SDK integration for fl_select.
///
/// Exposes fl_select widgets as GenUI `CatalogItem`s so that AI agents can
/// render real selection UIs inside chat surfaces and receive user selections
/// back as structured data (via `toQueryMap`-style encoding).
library;

export 'src/catalog/fl_select_catalog.dart';
export 'src/catalog/schema/select_entry_schema.dart';
