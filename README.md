# ResQ — Offline Emergency Intelligence

**An offline-first emergency companion powered by Gemma 4. No internet. No cloud. No accounts.**

Built for **Build with Gemma: AI for Africa Hackathon — FUTMinna 2026**.

---

## The Problem

It is 11:30 PM at the Federal University of Technology, Minna (FUTMinna). A student is walking back from night class at the Gidan Kwano campus. The path from the lecture halls to the hostels passes through bushland. He feels a sharp pain in his ankle. A snake slithers away into the grass. The university clinic is closed. The nearest hospital is 4 hours away.

This is everyday reality across rural Nigeria. In the critical minutes between an incident and professional care, there is no internet, no doctor, and no guidance. Panic leads to tourniquets on snake bites, butter on burns, moving fracture victims — actions that cause permanent harm.

---

## What ResQ Does

ResQ runs entirely on your phone. Tap **Start Emergency**, capture an image, speak or type what happened. Gemma 4 analyses both your photo and your words, then shows structured guidance in five calm, scannable cards:

- **Current Assessment** — what we understand right now
- **Immediate Actions** — steps to take, in order
- **Things To Avoid** — critical mistakes to prevent
- **Monitor** — signs to watch for changes
- **When To Seek Care** — red flags requiring urgent help

After guidance, Gemma 4 generates a **medical summary** formatted for healthcare providers — timeline, symptoms, visible findings, actions taken. The **Continue To Care** screen shows your emergency contacts, report sharing, and nearby medical facilities sorted by GPS (loaded from a local JSON database when offline).

---

## How Gemma 4 Powers ResQ

**Multimodal analysis.** Gemma 4's vision encoder processes injury photos (burns, wounds, swelling) while its language model reasons about the voice description. The integrated assessment is impossible with text-only models.

**On-device inference.** At 2.4B effective parameters, Gemma 4 E2B runs efficiently on a phone via LiteRT. No cloud calls. Works in airplane mode.

**Dynamic reasoning, not scripts.** Follow-up questions are never hardcoded. Gemma 4 reasons about what information it needs — a snake bite generates different questions than a burn.

**Structured JSON pipeline.** Five specialised prompt templates force Gemma 4 to produce structured JSON instead of conversational text:

```
Emergency Analysis → {"type", "severity", "context", "nextQuestion"}
Guidance Generation → {"assessment", "actions", "avoid", "monitor", "seekCare"}
Medical Summary    → Professional report for healthcare providers
```

The engine runs in `lib/shared/services/gemma_service.dart`. An identical pipeline runs in the [Kaggle notebook](https://www.kaggle.com/code/thejohncaleb/resq-offline-emergency-intelligence).

---

## Architecture

```
Phone (Flutter)                          Kaggle (Python Notebook)
+----------------------------+          +---------------------------+
| Camera + Voice input       |          | Emergency scenario input  |
+----------------------------+          +---------------------------+
| GemmaService               |<─same──>| Same prompt templates     |
| - analyzeEmergency()       | prompts | - buildEmergencyPrompt()  |
| - generateGuidance()       |          | - buildGuidancePrompt()   |
| - generateSummary()        |          | - buildSummaryPrompt()    |
+----------------------------+          +---------------------------+
| flutter_gemma / LiteRT     |          | transformers / Gemma 4   |
+----------------------------+          +---------------------------+
| SQLite | Secure Storage    |
| Local facilities JSON      |
+----------------------------+
```

```
lib/
+-- core/theme/          Material 3, teal colour palette
+-- core/routing/        GoRouter
+-- features/home/       Home screen + Start Emergency
+-- features/emergency/  Camera, voice, flashcards, AI guidance
+-- features/medical_profile/    Encrypted local profile
+-- features/medical_summary/    Professional reports
+-- features/continue_to_care/  Facilities, contacts, sharing
+-- features/care_history/      Past session timeline
+-- shared/services/     GemmaService, DatabaseService
+-- shared/providers/    Riverpod state management
+-- shared/widgets/      CalmButton, SectionCard, AppIcon (HugeIcons)
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| AI | Gemma 4 E2B via flutter_gemma + LiteRT |
| Framework | Flutter / Dart |
| State | Riverpod |
| Routing | GoRouter |
| Database | SQLite (sqflite) |
| Profile | flutter_secure_storage (encrypted) |
| UI | Material 3, HugeIcons, Inter font |
| Location | geolocator |

---

## Setup

```bash
git clone https://github.com/thejohncaleb/resq.git
cd resq
flutter pub get
flutter run
```

### Gemma 4 Model

The app downloads the model on first launch (~500MB). It saves to your app storage and loads automatically on restart.

If in-app download doesn't work on your device, push manually:
```bash
adb push model.bin /data/local/tmp/llm/model.bin
```

The app works without the model using a keyword-based classification engine covering 14 emergency types — so it always provides useful guidance.

---

## Setup

### Prerequisites

- Flutter SDK 3.41 or later
- Android device or emulator (API 21+)
- About 1 GB free storage for the Gemma model

### Clone and Run

```bash
git clone https://github.com/thejohncaleb/resq.git
cd resq
flutter pub get
flutter run
```

### Getting the AI Ready

To provide the best emergency guidance, ResQ needs an AI model on your device. This happens once, automatically.

**Let the app do it**

Open the app and a setup card will appear. Tap **Download** and wait a few minutes. The file saves to your `Downloads/ResQ/` folder and installs itself. Restart the app and you are ready.

**Manual setup (if automatic fails)**

Connect your phone to a computer via USB and run:

```bash
adb push model.bin /data/local/tmp/llm/model.bin
```

Restart the app and the AI will load automatically.

---

## Why This Matters

Every feature was designed from real scenarios around Minna:

- A student bitten by a snake walking from night class at Gidan Kwano
- A student with a kitchen burn in an off-campus hostel, alone
- A farmer in rural Niger State with no clinic within two hours
- A mother whose child has a severe allergic reaction, no pharmacy nearby

Three principles guided every decision:

**AI is invisible.** Users interact with emergency cards, not a chatbot. The model runs silently behind the scenes.

**Offline by design.** No Firebase. No cloud. No login. SQLite for data. Local JSON for facilities. Works in airplane mode.

**Calm under pressure.** Muted teal palette. Red only for medical warnings. Generous whitespace. One instruction per line. No animations.

---

## Submission

- **Hackathon:** Build with Gemma: AI for Africa — Minna 2026
- **Track:** AI for Social Impact / Edge and Offline AI
- **Kaggle Notebook:** [ResQ — Offline Emergency Intelligence](https://www.kaggle.com/code/thejohncaleb/resq-offline-emergency-intelligence)
- **GitHub:** [github.com/thejohncaleb/resq](https://github.com/thejohncaleb/resq)

---

Built for the moments that matter most.
