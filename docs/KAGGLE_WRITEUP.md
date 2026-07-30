# ResQ: Offline Emergency Intelligence with Gemma 4

**Team:** THEJOHNCALEB
**Track:** AI for Social Impact / Edge and Offline AI
**Repository:** github.com/THEJOHNCALEB/resq
**Model:** Gemma 4 E2B (litert-community/gemma-4-E2B-it-litert-lm)
**Platform:** Android app (no website — on-device only)

---

## What is ResQ?

ResQ is an Android app — not a website, not a cloud service. It runs entirely on your phone with zero internet required after the initial model download. It uses Gemma 4 E2B to analyse emergency situations — combining camera images, voice recordings, and text — then provides calm, structured guidance in five colour-coded cards. Everything happens on the device. Nothing leaves the phone.

---

## The Problem

It is 9 PM at FUTMinna. A student walks back from night class at Gidan Kwano campus. A snake bites his ankle. The university clinic is closed. The nearest hospital is 45 minutes away. His phone has no signal.

In rural Nigeria, emergency medical care is often hours away. The minutes between an incident and professional care are when permanent harm happens — tourniquets on snake bites, butter on burns, moving fracture victims incorrectly. Existing solutions need internet, which is the first thing to go. ChatGPT cannot help when there is no signal.

---

## Why Gemma On-Device?

The decisive question: why would someone use this instead of calling for help? Because help is often unreachable. The nearest clinic might be two hours away. Mobile data might be unavailable. In these moments, the phone is the only resource available. Processing on-device is not a feature — it is the entire reason the app exists.

We chose Gemma 4 E2B because:

- **Multimodal.** Camera images of injuries and voice descriptions are analysed together. The vision encoder processes what it sees. The language model reasons about what is described. Text-only models cannot do this.
- **It fits on a phone.** At 2.4 billion effective parameters, the LiteRT-LM model runs on mid-range Android devices.
- **It reasons, not scripts.** Follow-up questions are dynamically reasoned — snake bites generate different questions than burns.

---

## Architecture: What the Model Owns

The core decision: structured UI owns the experience; Gemma owns the understanding.

**What Flutter does:** Render colour-coded guidance cards, store encrypted medical profiles via SQLite, calculate GPS proximity to facilities from a local JSON database, record audio and capture images.

**What Gemma does:** Analyse images and voice together, determine emergency type and severity, generate structured JSON guidance, write professional medical summaries, dynamically reason about follow-up questions.

This split means the UI is never raw AI text. Every prompt forces JSON output.

---

## Technical Implementation

**Inference stack:** flutter_gemma 1.3.0 + flutter_gemma_litertlm (LiteRT-LM engine). The engine is initialised at startup via `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])`. The ~2.4GB model downloads on first launch from Hugging Face using Dart's HttpClient with progress tracking.

**Multimodal pipeline:** Five prompt templates force Gemma to produce structured JSON. The emergency analysis receives actual image bytes via `Message.withImage()`, not text descriptions. The guidance prompt returns a JSON object with assessment, actions, avoid, monitor, and seekCare fields — parsed and rendered as five colour-coded cards.

**Privacy:** A `PrivacyMonitor` singleton intercepts all HTTP via `HttpOverrides`. A live counter on the home screen shows "0 outbound" — a measurement, not a promise. `google_fonts` was removed entirely. Inter is bundled as an asset.

**Project structure:**
```
lib/
+-- main.dart         FlutterGemma.initialize + LiteRtLmEngine + PrivacyMonitor
+-- core/             Theme (Material 3), routing (GoRouter), privacy monitor
+-- features/
|   +-- emergency/    Camera, voice, flashcards, AI guidance
|   +-- home/         Bottom nav (Home, History, Profile)
|   +-- medical_*/    Encrypted profile, summaries, continue to care, history
+-- shared/           GemmaService, DatabaseService, Riverpod providers
```

**Tech stack:** Flutter 3.44, Riverpod, GoRouter, SQLite (sqflite), flutter_secure_storage, HugeIcons, bundled Inter font.

---

## Challenges

**Flutter SDK upgrade.** The winning team from GDG Embu (Chapaa) used flutter_gemma 1.3.0 which requires Dart 3.12+. Our Flutter was on 3.41.9 (Dart 3.11.5). Upgrading to Flutter 3.44.8 mid-sprint was risky but necessary for Gemma 4 support.

**Model path on Android.** flutter_gemma 0.1.x hardcoded the model path to `/data/local/tmp/llm/` which requires root on some devices. The 1.x API solves this with `FlutterGemma.installModel().fromFile()` — the model can live anywhere writable.

**Multimodal input.** Getting camera, voice, and text to work reliably in a single emergency flow required careful state management. The recording was initially silent — fixed by adding explicit sample rate and channel configuration.

**Offline font loading.** `google_fonts` makes a runtime network request on first launch, ruining the "0 outbound" privacy claim. We downloaded Inter TTF files from Google Fonts CSS API, bundled them as local assets, and removed the package entirely.

---

## What Makes ResQ Different

Most AI apps shove a chatbot in your face. ResQ deliberately hides the AI — users interact with colour-coded emergency cards, not conversations. The guidance is calm, structured, and designed to combat panic.

The multimodal analysis (camera + voice + text) is genuine Gemma 4 usage, not a text-only wrapper. The privacy claim is measured, not promised. The app works where it matters most — with no internet, no cloud, no accounts.

For a student bitten by a snake on the way from night class at FUTMinna, ResQ turns a moment of panic into a moment of clarity.
