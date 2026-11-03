# fl_select_genui example

A demo app showing the end-to-end GenUI (A2UI) flow of `fl_select_genui`:

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

The demo's **Agent chat** button opens a chat page backed by a real model:
the model answers with A2UI JSON, the page renders any `Select` it emits, and
**Send selection** posts the chosen values back as the next user turn.

It speaks the OpenAI-compatible `/chat/completions` protocol (OpenAI,
DeepSeek, Moonshot, Qwen, ...). Pass the key at launch; it is never written to
disk:

```bash
flutter run -d macos \
  --dart-define=LLM_API_KEY=<your key> \
  --dart-define=LLM_BASE_URL=https://api.openai.com/v1 \
  --dart-define=LLM_MODEL=gpt-4o-mini
```

`LLM_BASE_URL` and `LLM_MODEL` are optional. Try "Help me pick a hotel" or "I
want to sort the results".
