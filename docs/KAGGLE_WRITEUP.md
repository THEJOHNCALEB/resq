# ResQ — Offline Emergency Intelligence

**Team:** THEJOHNCALEB
**Track:** AI for Social Impact / Edge and Offline AI
**Repository:** github.com/THEJOHNCALEB/resq
**Model:** Gemma 4 E2B (litert-community/gemma-4-E2B-it-litert-lm)

---

## What is ResQ?

ResQ is an on-device emergency companion for the critical minutes between an incident and professional medical care. It uses Gemma 4 E2B to analyse emergencies — combining camera photos, voice recordings, and text — then provides calm, structured guidance as colour-coded cards. Everything happens on the phone. Nothing leaves the device.

ResQ is not a chatbot. It is an emergency tool for places where internet and immediate healthcare are unavailable.

## The Problem

It is 11:30 PM at FUTMinna. A student walks back from night class at Gidan Kwano campus. A snake bites his ankle. The university clinic is closed. The nearest hospital is 1 hour away. His phone has no signal.

In rural Nigeria, emergency care is often hours away. In those critical minutes, panic leads to harmful actions — tourniquets on snake bites, butter on burns, moving fracture victims incorrectly. ChatGPT cannot help when there is no signal.

## Why Gemma On-Device?

The decisive question: *"Why not just paste this into ChatGPT?"*

ResQ's answer is unanswerable: **when you are bitten by a snake on a dark road with no signal, no cloud AI can reach you.** Processing on-device is not a feature — it is the entire reason the app exists.

We chose Gemma 4 E2B specifically because:

1. **It fits on a phone.** The 2.4GB LiteRT-LM model runs on mid-range Android devices with 4GB+ RAM.
2. **It is multimodal.** Camera images of injuries and voice descriptions are analysed together through the vision encoder.
3. **It reasons, not scripts.** Snake bites generate different follow-up questions than burns. No hardcoded decision trees.

## Architecture: The Split of Responsibility

The core design decision: **deterministic code owns safety and data; Gemma owns understanding.**

### What deterministic code does (never the model):
- Render colour-coded guidance cards from structured JSON
- Store encrypted medical profiles via flutter_secure_storage
- Calculate GPS proximity to nearby facilities from a local JSON database
- Record audio and capture camera images
- Save complete emergency session timelines to SQLite
- Execute all tool functions (get_medical_profile, get_nearby_facilities)

### What Gemma does (only the model can):
- Analyse camera images and voice recordings together via the vision encoder
- Determine emergency type and severity from multimodal input
- Generate structured JSON with tailored guidance cards
- Write professional medical summaries for healthcare providers
- Call tools to query the patient's medical profile and nearby facilities before responding

This split means guidance is always clean and structured. The UI is never raw AI text. And the model can never hallucinate facility names or medical history — it queries them from real on-device data.

## Technical Implementation

### On-Device Inference Pipeline

We use `flutter_gemma` (v1.3.0) with the `flutter_gemma_litertlm` engine. The model downloads once from Hugging Face (~2.4GB) and is loaded with a 90-second timeout. All subsequent calls reuse the cached instance.

**One-shot inference:** `createSession()` + `getResponse()` for single-pass prompts (emergency analysis). Temperature 0.0, topK=1 for deterministic output.

**Agent-based guidance:** `createChat()` + `generateChatResponse()` with function-calling tools for interactive guidance. The agent loop (max 6 hops) lets Gemma call tools to query real data before generating cards.

### Function Calling (2 Tools)

| Tool | Purpose | Example |
|------|---------|---------|
| `get_medical_profile` | Patient's allergies, conditions, medications, blood type | "Is the patient allergic to anything?" |
| `get_nearby_facilities` | Nearest hospitals from local offline database | "Where is the closest hospital?" |

Every tool call is traced. The model decides which tools to call, but the data comes from Dart — never hallucinated.

### The Agent Loop

`ResQAgent.ask()` implements a function-calling loop (max 6 hops):
1. Send the emergency description to Gemma
2. If Gemma returns a `FunctionCallResponse`, execute the tool via `ResQToolExecutor`
3. Feed the result back via `Message.toolResponse()`
4. Repeat until Gemma returns a text response with structured JSON cards
5. Record all `TraceStep`s for auditability

### Frameworks

| Layer | Technology |
|---|---|
| **Inference** | flutter_gemma (v1.3.0) + flutter_gemma_litertlm |
| **App** | Flutter 3.44, Dart 3.12, Riverpod, GoRouter |
| **Storage** | SQLite (sqflite), flutter_secure_storage |
| **UI** | Material 3, HugeIcons, bundled Inter font |
| **Offline** | PrivacyMonitor (live HTTP counter), local JSON facilities |

## Privacy: Proof, Not a Promise

- **Zero network requests after initial huggingface gemma download.** A `PrivacyMonitor` singleton intercepts all HTTP. The privacy seal is a live counter showing "0 outbound" — a measurement, not a badge.
- **No cloud fonts.** Bundled Inter as a local asset. A Google Fonts runtime fetch would have broken the "0 requests" seal.
- **No real data in the repo.** `.gitignore` blocks `*.task`, `*.bin`, `*.litertlm`, `*.m4a`, and `config.json`.
- **The demo moment:** Open Android devtools and verify zero traffic. That is the pitch.

## UI: Calm Under Pressure

The design language is built around calmness under pressure. Muted teal palette. Red reserved exclusively for emergencies. Large typography. Generous whitespace. One instruction per line.

Key screens:
- **Home:** Large red emergency button with pulse animation. Privacy counter in the corner. Profile, Home, and History tabs.
- **Emergency Flow:** Camera opens immediately. Photo, voice recording, and text input. One tap to guidance.
- **Guidance Cards:** Full-width colour-coded cards stacked seamlessly. The AI decides which cards to show based on the emergency — not always the same five. A "Find Hospitals" card with map overlay opens Google Maps.
- **Medical Summary:** AI-generated report for healthcare providers, rendered in markdown.
- **Care History:** Complete timeline of past sessions with detail views.

## Challenges & Solutions

1. **Flutter SDK upgrade:** flutter_gemma 1.3.0 requires Dart 3.12+. Upgraded from Flutter 3.41.9 to 3.44.8 mid-sprint. All 54 packages resolved.

2. **Model path on Android:** Older flutter_gemma hardcoded paths that were permission-restricted. The 1.x API solves this with `installModel().fromFile()` — loads from any writable app directory.

3. **Session vs Chat API:** One-shot prompts use `createSession()` for speed. Interactive guidance uses `createChat()` with function calling so the agent can query real on-device data.

4. **Multimodal input:** Getting camera, voice, and text to work reliably required careful state management. Recording failures fixed with explicit sample rate (44100) and mono channel config.

5. **Offline font loading:** google_fonts makes a runtime network request. Removed it entirely and bundled Inter as a local asset to preserve the zero-outbound guarantee.

6. **Real image analysis:** Initial implementation only passed text. Passing actual `Uint8List` image bytes via `Message.withImage()` with `enableVisionModality: true` lets Gemma correlate visible injuries with voice descriptions.

## What Makes ResQ Different

Most AI apps shove a chatbot in your face. ResQ deliberately hides the AI — users interact with colour-coded emergency cards, not conversations. The guidance is calm, structured, and designed to combat panic.

The function-calling agent means the guidance is grounded in real data — the user's actual medical profile, the nearest real hospital from the local database. Nothing is hallucinated.

The privacy claim is measured, not promised: a live HTTP counter proves zero outbound requests after model download. The app works where it matters most — with no internet, no cloud, no accounts.

For a student bitten by a snake on the way from night class at FUTMinna, ResQ turns a moment of panic into a moment of clarity.

---

Built for **Build with Gemma: AI for Africa — FUTMinna 2026**
