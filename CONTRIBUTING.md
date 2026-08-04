# Contributing to ResQ

Thank you for wanting to contribute to ResQ! This project is an open-source, on-device emergency intelligence companion built with Flutter and Gemma 4 E2B.

## Development Setup

1. **Prerequisites**: Flutter 3.44+, an Android device with 4GB+ RAM (for on-device inference).
2. **Get the code**:
   ```bash
   git clone https://github.com/THEJOHNCALEB/resq.git
   cd resq
   ```
3. **Configure the Hugging Face token**:
   ```bash
   cp config.example.json config.json
   # Edit config.json and paste your Hugging Face read token
   # config.json is gitignored — never commit it
   ```
4. **Install dependencies & run**:
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=config.json
   ```

> The ~2.4GB Gemma model downloads automatically on first launch. Subsequent launches reuse the cached model.

## Codebase Overview

```
lib/
├── core/          # Constants, routing, theme, privacy monitor
├── features/      # Feature folders: data/ (models, repos) + presentation/ (pages, widgets)
├── shared/
│   ├── providers/ # Riverpod providers
│   ├── services/  # GemmaService, agent loop, tools, facilities, location, database
│   └── widgets/   # Reusable UI widgets
```

The AI pipeline lives in `lib/shared/services/`:

- `gemma_service.dart` — model download/load, sessions, chat creation
- `agent/` — the function-calling agent loop (`ResQAgent`) and tools (`ResQToolExecutor`)

## Branching & Commits

- Branch names: `feature/<short-description>` or `fix/<short-description>`.
- Keep commits focused and atomic. Follow the existing commit style (imperative, concise summary line).
- Never commit secrets: `config.json`, model files (`*.litertlm`), or captured media (`*.m4a`) are gitignored — don't force-add them.

## Pull Request Process

1. Fork the repo and create your branch.
2. Make your changes, keeping the existing code style and patterns.
3. Run the analyzer and tests before submitting:
   ```bash
   flutter analyze
   flutter test
   ```
4. Open a PR against `main` with a clear description of what and why.
5. A maintainer will review. Address feedback, and keep the PR reasonably small — it merges faster.

## Releases

APKs are built automatically by GitHub Actions when a `v*` tag is pushed:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Notes

- The project targets **Android** as the primary platform. iOS builds are supported for the model but the LiteRT-LM engine may not work on desktop (macOS).
- The app must remain **100% offline after the model download** — do not introduce network calls (including font or package fetches) that would break the "0 outbound" privacy seal.

Questions? Open an issue.
