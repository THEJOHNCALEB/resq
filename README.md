# ResQ — Offline Emergency Intelligence

**An on-device emergency companion powered by Gemma 4. No internet. No cloud. No accounts.**

Built for **Build with Gemma: AI for Africa Hackathon — FUTMinna 2026**

---

## What is ResQ?

ResQ is an on-device emergency intelligence companion that runs entirely on your phone. It uses **Gemma 4 E2B** to analyse emergency situations — combining camera images, voice descriptions, and text — then provides calm, structured guidance when you need it most. Everything happens on the device. Nothing leaves your phone.

It is not a chatbot. It is not a symptom checker. It is an emergency tool designed for the moments between an incident and professional care — when there is no internet, no doctor, and no one to tell you what to do.

---

## The Problem

It is 9 PM at FUTMinna. A student walks back from night class at Gidan Kwano campus. The path to the hostels passes through bushland. A snake bites his ankle. The university clinic is closed. The nearest hospital is 45 minutes away.

In rural Nigeria, emergency medical care is often hours away. A farmer bitten by a snake. A mother whose child has a severe allergic reaction in a village with no clinic. A student who burns themselves cooking in a hostel with no first aid. In these critical minutes, panic leads to harmful actions — tourniquets on snake bites, butter on burns, moving fracture victims — that cause permanent harm.

Existing solutions fail because they need internet, which is the first thing to go in these situations. ChatGPT cannot help when there is no signal.

---

## Why Gemma On-Device?

The decisive question for any emergency AI: why would someone use this instead of calling for help?

Because help is often unreachable. The nearest clinic might be two hours away. Mobile data might be expensive or unavailable. In these moments, the phone is the only resource available. Processing on-device is not a feature — it is the entire reason the app exists.

We chose **Gemma 4 E2B** because:

- **It is multimodal.** Camera images of injuries and voice descriptions are analysed together. The vision encoder processes what it sees (burns, swelling, bite marks). The language model reasons about what is described. The integrated assessment is impossible with text-only models.
- **It fits on a phone.** At 2.4 billion effective parameters, the LiteRT-LM model runs on mid-range Android devices with 4GB+ RAM.
- **It reasons, not scripts.** Follow-up questions are dynamically reasoned by the model — snake bites generate different questions than burns. No hardcoded decision trees.

---

## Architecture: What the Model Owns vs What Code Owns

The core design decision: **structured UI owns the experience; Gemma owns the understanding.**

What the Flutter app does (never the model):
- Render five calm guidance cards (Assessment, Actions, Avoid, Monitor, Seek Care)
- Store encrypted medical profiles and emergency history via SQLite
- Calculate GPS proximity to nearby medical facilities from a local JSON database
- Record audio and capture camera images
- Generate formatted medical summaries for healthcare providers

What Gemma does (only the model can):
- Analyse emergency images and voice transcriptions together
- Determine emergency type and severity from multimodal input
- Generate structured JSON guidance (assessment, actions to take, things to avoid, signs to monitor, when to seek professional care)
- Write professional medical summaries for healthcare providers
- Dynamically reason about what follow-up questions to ask

This split means the guidance format is always clean and structured, regardless of the model's output. The UI is never raw AI text.

---

## Technical Implementation

### On-Device Inference

```
flutter_gemma (v1.3.0)          ← Core plugin API
    └── flutter_gemma_litertlm   ← LiteRT-LM engine backend
```

The app initialises the LiteRT-LM engine at startup via `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])`. The Gemma 4 E2B model (~2.4GB) downloads on first launch from Hugging Face using Dart's `dart:io` HttpClient and installs via `FlutterGemma.installModel().fromFile()`.

Every prompt is structured to force JSON output — never conversational text. The five guidance sections are populated by parsing Gemma's JSON response, not by displaying raw model output.

### Project Structure

```
lib/
+-- main.dart                 FlutterGemma.initialize + LiteRtLmEngine + PrivacyMonitor
+-- app.dart                  MaterialApp + router config
+-- core/
|   +-- privacy_monitor.dart  Live HTTP request counter
|   +-- privacy_guard_io.dart  Native HttpOverrides interceptor
|   +-- privacy_guard_web.dart Web fetch/XHR patching
|   +-- theme/                "Calm Medical" design tokens
|   +-- routing/              GoRouter declarative navigation
+-- features/
|   +-- home/                 Home screen + emergency button + download screen
|   +-- emergency/            Camera, voice, flashcards, AI guidance
|   +-- medical_profile/      Encrypted local profile (flutter_secure_storage)
|   +-- medical_summary/      Professional medical reports
|   +-- continue_to_care/     Facilities, contacts, report sharing
|   +-- care_history/         Past session timeline and detail
+-- shared/
    +-- services/             GemmaService, DatabaseService, LocationService
    +-- providers/            Riverpod dependency injection
    +-- widgets/              CalmButton, GuidanceCard, AppIcon (HugeIcons)
```

### The Prompt Pipeline

Five prompt templates force Gemma to produce structured JSON:

```
Emergency Analysis → {"type", "severity", "context", "nextQuestion"}
Guidance Generation → {"assessment", "actions", "avoid", "monitor", "seekCare"}
Medical Summary    → Professional healthcare narrative
```

The same pipeline runs in the [Kaggle notebook](https://www.kaggle.com/code/thejohncaleb/resq-offline-emergency-intelligence) for verification.

### Tech Stack

| Layer | Tech |
|---|---|
| AI Model | Gemma 4 E2B (multimodal, 2.4B params) |
| AI Runtime | flutter_gemma 1.3.0 + flutter_gemma_litertlm (LiteRT-LM) |
| Framework | Flutter 3.44 / Dart 3.12 |
| State | Riverpod |
| Routing | GoRouter |
| Database | SQLite (sqflite) |
| Security | flutter_secure_storage (encrypted profiles) |
| UI | Material 3, HugeIcons, Inter font |

---

## Privacy: Proof, Not a Promise

ResQ makes zero network requests after model download. This is not a claim — it is **measured**.

A `PrivacyMonitor` singleton intercepts all HTTP traffic via `HttpOverrides` on native and `fetch`/`XMLHttpRequest` patching on web. The count is displayed live in the app as "0 network requests." A judge can open Android devtools and verify zero traffic.

There is no backend. No Firebase. No cloud APIs. No authentication. No user accounts. The model runs on-device. Medical profiles are encrypted locally via `flutter_secure_storage`. Emergency history stays in local SQLite.

---

## The Design

The design language is built around calmness under pressure. Muted teal palette. Red reserved exclusively for medical warnings. Large typography. Generous whitespace. One instruction per line. No unnecessary animations. The guidance is presented as swipeable flashcards — never a chat interface.

The AI is invisible by design. Users interact with structured emergency cards, not a chatbot.

---

## Setup

### Download APK

Get the latest release APK from the [Releases](https://github.com/thejohncaleb/resq/releases) page. Each tagged version triggers a GitHub Actions build.

### Build from Source

**Prerequisites:**
- Flutter 3.44+ (Dart 3.12+)
- Android (API 26+) or iOS (16.0+) device
- 4GB+ RAM, ~3GB free storage
- A free [Hugging Face read token](https://huggingface.co/settings/tokens)

```bash
git clone https://github.com/thejohncaleb/resq.git
cd resq

cp config.example.json config.json
# Edit config.json with your HF token

flutter pub get

# Option 1: VS Code (recommended) — just press F5
# Launch config already included in .vscode/launch.json

# Option 2: Terminal
flutter run --dart-define-from-file=config.json
```

### GitHub Actions / CI

For the release workflow to build with model support, add your HuggingFace token as a GitHub Secret:

1. Go to your repo → Settings → Secrets and variables → Actions
2. Add `HUGGINGFACE_TOKEN` with your HF read token
3. Tagged pushes (`v1.0.0`) will automatically build signed APKs

### Model Setup

The Gemma 4 E2B model downloads automatically on first launch (~2.4GB). If automatic download fails:

```bash
# Android
adb push gemma-4-E2B-it.litertlm /sdcard/Android/data/com.resq.resq/files/

# iOS
# Use Finder/iTunes File Sharing to copy the model into the app's documents
```

---

## Tests

```bash
flutter test
```

6 pipeline tests cover the deterministic side of the app: emergency session serialization, medical profile encryption, and JSON roundtrip integrity. The model is never needed for tests — all money math and data handling is verified independently.

---

## Real Scenarios

Every feature was designed from real situations around Minna and Niger State:

- A student bitten by a snake walking from night class at Gidan Kwano
- A student with a kitchen burn in an off-campus hostel, alone
- A farmer in rural Niger State with no clinic within two hours
- A mother whose child has a severe allergic reaction, no pharmacy nearby

---

## Submission

- **Hackathon:** Build with Gemma: AI for Africa — Minna 2026
- **Track:** AI for Social Impact / Edge and Offline AI
- **Kaggle Notebook:** [ResQ — Offline Emergency Intelligence](https://www.kaggle.com/code/thejohncaleb/resq-offline-emergency-intelligence)
- **GitHub:** [github.com/thejohncaleb/resq](https://github.com/thejohncaleb/resq)

---

Built for the minutes that matter most.
