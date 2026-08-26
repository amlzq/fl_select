# fl_select_genui example

A demo app showing the end-to-end GenUI (A2UI) flow of `fl_select_genui`:

1. **Agent payload** — a JSON payload as a conversational AI agent would
   produce it for a chat surface.
2. **Rendered filter** — the payload is resolved through the package's
   catalog and rendered as a regular `fl_select` filter widget.
3. **Structured selection** — the user's selection is written back to the
   data model and returned as structured query data.

## Run

```bash
cd example
flutter run
```
