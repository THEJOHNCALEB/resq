# ResQ: Offline Emergency Intelligence with Gemma 4

**Team:** THEJOHNCALEB
**Track:** AI for Social Impact / Edge and Offline AI
**Model:** Gemma 4 E2B (litert-community/gemma-4-E2B-it-litert-lm)
**Platform:** Android app — no website, no cloud, on-device only

---

## Inspiration

It is 9 PM at FUTMinna. A student walks back from night class at Gidan Kwano campus. A snake bites his ankle. The university clinic is closed. The nearest hospital is 45 minutes away. His phone has no signal.

In rural Nigeria, this is everyday reality. A farmer bitten by a snake. A mother whose child has a severe allergic reaction. A student who burns themselves cooking in a hostel alone. The minutes between an incident and professional care are when permanent harm happens — tourniquets on snake bites, butter on burns, moving fracture victims incorrectly.

Existing solutions need internet, which is the first thing to go in an emergency. ChatGPT cannot help when there is no signal. We built ResQ for these critical minutes — an emergency intelligence companion that works entirely on-device, with zero internet required.

---

## How We Built It

### Gemma Model

We used **Gemma 4 E2B** (2.4B effective parameters, multimodal) via `flutter_gemma` 1.3.0 with the `flutter_gemma_litertlm` engine (LiteRT-LM). The engine is initialised at startup:

```dart
FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
```

The model downloads on first launch (~2.4GB) from Hugging Face and installs via `FlutterGemma.installModel().fromFile()`.

### Prompt Engineering

We chose prompt engineering over fine-tuning. Five templates force Gemma into structured JSON output — never conversational text:

```
Emergency Analysis → {"type", "severity", "context", "nextQuestion"}
Guidance → {"assessment", "actions", "avoid", "monitor", "seekCare"}
Medical Summary → Professional healthcare narrative
```

This split means the UI is never raw AI text. Every response is parsed as JSON and rendered as colour-coded cards.

### Multimodal Pipeline

The emergency analysis receives actual image bytes via `Message.withImage()` — not text descriptions of the image. Camera photos of injuries are passed directly to Gemma 4's vision encoder alongside the voice recording and typed description.

### Frameworks

- **Inference:** flutter_gemma (v1.3.0) + flutter_gemma_litertlm
- **App:** Flutter 3.44, Riverpod (state), GoRouter (navigation)
- **Storage:** SQLite (sqflite), flutter_secure_storage (encrypted profiles)
- **UI:** Material 3, HugeIcons, bundled Inter font
- **Offline:** PrivacyMonitor (live HTTP counter), local JSON facilities database

### Architecture

Predictable code owns the UI and data. Gemma owns understanding.

| Code Owns | Gemma Owns |
|---|---|
| Structured guidance card rendering | Analysing images and voice together |
| Encrypted medical profiles (SQLite) | Determining emergency type and severity |
| GPS proximity to facilities | Generating structured JSON guidance |
| Audio recording + camera capture | Writing medical summaries |

---

## The Prototype

- **Demo Video:** [YouTube link — add your video URL here]
- **GitHub Repository:** [github.com/THEJOHNCALEB/resq](https://github.com/THEJOHNCALEB/resq)

The app flow: Home → tap the red emergency button → camera opens → take a photo → describe what happened (type or record voice) → five colour-coded guidance cards (Assessment, Actions, Avoid, Monitor, Seek Care) → generate medical summary → continue to care (facilities, contacts, maps).

---

## Challenges We Ran Into

**Flutter SDK upgrade.** flutter_gemma 1.3.0 requires Dart 3.12+. Our Flutter was on 3.41.9 (Dart 3.11.5). Upgrading to 3.44.8 mid-sprint was risky but necessary for Gemma 4 multimodal support.

**Model path on Android.** flutter_gemma 0.1.x hardcoded the model to `/data/local/tmp/llm/` which is permission-restricted on many devices. The 1.x API solves this with `installModel().fromFile()` — the model loads from any writable path.

**Multimodal input.** Getting camera, voice, and text to work reliably in a single emergency flow required careful state management. Recording was initially silent — fixed by adding explicit sample rate and channel config.

**Offline font loading.** `google_fonts` makes a network request on first launch, which would break our "0 outbound" privacy claim. We downloaded Inter TTF files and bundled them as local assets.

**Real image analysis.** Our initial implementation only passed text to Gemma. Passing actual `Uint8List` image bytes via `Message.withImage()` required enabling `supportImage: true` on the chat session. Once fixed, the model correctly correlated visible injuries with the voice description.

---

## What Makes ResQ Different

ResQ is not a chatbot. The AI is deliberately invisible — users interact with colour-coded emergency cards, not conversations. The guidance is calm, structured, and designed to combat panic.

The multimodal analysis is genuine Gemma 4 usage — camera + voice + text analysed together. The privacy claim is measured, not promised: a live HTTP counter proves zero outbound requests after model download.

For a student bitten by a snake on the way from night class at FUTMinna, ResQ turns a moment of panic into a moment of clarity — with no internet, no cloud, no accounts.

---

Built for **Build with Gemma: AI for Africa — FUTMinna 2026**
