# fl_select_genui example

An example app showing the end-to-end GenUI (A2UI) flow of `fl_select_genui`:

1. **Agent payload** — a JSON payload as a conversational AI agent would
   produce it for a chat surface.
2. **Rendered selection UI** — the payload is resolved through the package's
   catalog and rendered as a regular `fl_select` widget.
3. **Structured selection** — the user's selection is written back to the
   data model and returned as structured query data.

## Run

```bash
cd example
flutter run -d macos   # or: -d chrome, an iOS simulator, an Android device
```

## Agent chat (real model)

The example's **Agent chat** button opens a chat page backed by a real model:
the model answers with A2UI JSON, the page renders any `Select` it emits, and
**Send selection** posts the chosen values back as the next user turn.

It speaks the OpenAI-compatible `/chat/completions` protocol (OpenAI,
DeepSeek, Moonshot, Qwen, ...). Credentials live in a git-ignored
`dart_defines.local.json`; start from a template:

```bash
cp dart_defines.openai.example.json dart_defines.local.json    # OpenAI
cp dart_defines.deepseek.example.json dart_defines.local.json  # DeepSeek
```

then replace `LLM_API_KEY`. Launch with the file (the `fl_select_genui example`
VS Code configurations already do):

```bash
flutter run -d macos --dart-define-from-file=dart_defines.local.json
```

Try "Help me pick a hotel" or "I
want to sort the results".
