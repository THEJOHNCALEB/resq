# ResQ — Offline Emergency Intelligence

**An offline-first emergency companion powered by Gemma 4. No internet. No cloud. No accounts. Just your phone.**

Built for the **Build with Gemma: AI for Africa Hackathon — FUTMinna 2026**.

---

## The Problem

It is 11:30 PM at the Federal University of Technology, Minna (FUTMinna). A student is walking back from night class at the Gidan Kwano campus. The path from the lecture halls to the hostels passes through bushland. He feels a sharp pain in his ankle. A snake slithers away into the grass. The university clinic is closed. The nearest hospital is 4 hours away.

This is not a hypothetical. This is everyday reality for students, farmers, travellers, and families across Nigeria and rural Africa. In these critical minutes between an incident and professional medical care:

- There is no internet
- There is no doctor
- There is no one to tell you what to do

Panic leads to harmful decisions. People apply tourniquets to snake bites. They put butter on burns. They move fracture victims and cause permanent damage. They fail to recognise stroke symptoms until it is too late.

**ResQ exists for these minutes.**

---

## What ResQ Does

ResQ is an offline-first emergency intelligence companion that runs entirely on your phone. It uses **Gemma 4** — Google's latest open multimodal AI model — to provide calm, structured emergency guidance when you need it most.

It is **not** a chatbot. It is **not** a symptom checker. It is an emergency tool designed by someone who grew up hearing stories like the one above.

### The Experience

1. You tap **Start Emergency**
2. The camera opens — you photograph the situation
3. The app asks: "Tell me briefly what happened"
4. You speak or type your description
5. Gemma 4 analyses both your image and your words
6. You receive structured guidance in five clear sections:

| Section | What it tells you |
|---|---|
| Current Assessment | What we understand about the situation right now |
| Immediate Actions | Step-by-step instructions to follow |
| Things To Avoid | Critical mistakes that could make things worse |
| Monitor | Signs and changes to watch for |
| When To Seek Care | Red flags that mean you need professional help urgently |

7. After guidance, Gemma 4 generates a **medical summary** — a professionally formatted report designed to be handed to a doctor or paramedic when they arrive. It includes timeline, symptoms, visible findings, actions taken, and AI assessment.

8. The **Continue To Care** screen shows: your medical summary, emergency contacts, report sharing, and a list of nearby medical facilities sorted by your GPS location — loaded from a local database when you are offline.

---

## How Gemma 4 Powers ResQ

### Model Choice

I chose **Gemma 4 E2B** (2.4 billion effective parameters) for three reasons:

**Multimodal.** ResQ captures camera images and voice descriptions at the same time. Gemma 4's vision encoder processes the injury photo — burns, wounds, swelling, bite marks — while its language model reasons about the voice transcription. The integrated assessment is something a text-only model cannot do.

**On-device.** At 2.4B effective parameters, Gemma 4 E2B runs efficiently on a phone. No cloud API calls. No backend servers. No authentication. Everything happens on the device. This means the app works in airplane mode, in areas with zero connectivity, and in situations where data is too expensive to use.

**Reasoning, not scripting.** The follow-up questions ResQ asks are not hardcoded in a decision tree. Gemma 4 actively reasons about what additional information it needs. A snake bite generates different questions than a burn. An allergic reaction generates different questions than a fracture. The model determines the minimum number of questions needed — no more, no less.

### Prompt Engineering

The key innovation is not the model itself — it is the prompt engineering that makes the AI invisible. Gemma 4 outputs are forced into structured JSON through five specialised prompt templates:

```
Emergency Analysis   → {"type", "severity", "context", "nextQuestion"}
Guidance Generation   → {"assessment", "actions", "avoid", "monitor", "seekCare"}
Follow-up Questions   → Single most important question, dynamically reasoned
Medical Summary       → Professional narrative for healthcare providers
```

This guarantees:
- **Deterministic parsing** — JSON output can be programmatically extracted and rendered
- **Invisible AI** — users see structured cards, never raw model text
- **Calm UX** — short, simple instructions with generous whitespace
- **Consistency** — the same output format whether or not Gemma is available

The complete prompt pipeline is in `lib/shared/services/gemma_service.dart`. An identical implementation in Python is available in the Kaggle notebook — you can run it to see Gemma 4 producing real structured emergency guidance.

### When Gemma Is Not Available

The app includes a keyword-based emergency classification engine that covers 14 emergency types: bleeding, burns, fractures, allergic reactions, seizures, unconsciousness, breathing emergencies, poisoning, snake and animal bites, electrical injuries, road accidents, falls, physical assaults, and head injuries. Each type has specific guidance for actions to take, things to avoid, what to monitor, and when to seek care.

This means the app ALWAYS provides useful guidance — even before the model downloads, even if the model fails to load. The model enhances the experience; the app never depends on it to be useful.

---

## Features

- **Offline Gemma 4 inference** — via flutter_gemma and LiteRT, runs on-device
- **Camera capture** — photograph injuries, wounds, or the scene
- **Voice input** — speak your emergency description, recorded locally
- **Multimodal analysis** — Gemma 4 analyses image and text together
- **Dynamic follow-up questions** — AI-reasoned, not hardcoded
- **Structured guidance cards** — five clear sections, no chatbot interface
- **Medical summary** — professional report for healthcare providers
- **Continue To Care** — emergency contacts, report sharing, nearby facilities
- **Medical profile** — encrypted local storage for allergies, medications, blood group
- **Care history** — complete timeline of past emergency sessions
- **Offline facilities database** — bundled JSON of medical facilities, sorted by GPS
- **Material 3 design** — clean, calm, premium interface with large touch targets

---

## Architecture

```
Flutter App (Phone)                        Kaggle Notebook (Browser)
+-------------------------------+         +------------------------------+
| UI Layer (Material 3)         |         | Python + transformers        |
| Riverpod State Management     |         | Gemma 4 from Kaggle Hub      |
| GoRouter Navigation           |         |                              |
+-------------------------------+         | Same prompt templates        |
| GemmaService                  |<─same──>| buildEmergencyPrompt()       |
| - buildEmergencyPrompt()      | prompts | buildGuidancePrompt()        |
| - buildGuidancePrompt()       |         | buildSummaryPrompt()         |
| - buildSummaryPrompt()        |         |                              |
+-------------------------------+         +------------------------------+
| flutter_gemma / LiteRT        |         | Real Gemma 4 inference       |
| Runs on phone GPU             |         | Structured JSON output       |
+-------------------------------+         +------------------------------+
| SQLite (sqflite)              |
| Encrypted profile storage     |
| Local medical facilities JSON |
+-------------------------------+
```

```
lib/
+-- main.dart                          Entry point
+-- app.dart                           MaterialApp + router config
+-- core/
|   +-- theme/                         Material 3 theme, colour palette
|   +-- routing/                       GoRouter declarative navigation
|   +-- constants/                     App-wide constants
+-- features/
|   +-- home/                          Home screen + Start Emergency
|   +-- emergency/                     Emergency flow, AI guidance
|   |   +-- data/models/               EmergencySession model
|   |   +-- data/repositories/         SQLite persistence layer
|   |   +-- presentation/pages/        Camera, voice, flashcards, guidance
|   +-- medical_profile/               Encrypted local medical profile
|   +-- medical_summary/               Professional medical reports
|   +-- continue_to_care/              Post-emergency actions, facilities
|   +-- care_history/                  Past session review and detail
+-- shared/
    +-- services/                      GemmaService, DatabaseService, etc.
    +-- providers/                     Riverpod dependency injection
    +-- widgets/                       Reusable UI components
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| AI Model | Gemma 4 E2B (multimodal, on-device) |
| AI Runtime | flutter_gemma + MediaPipe LiteRT |
| Framework | Flutter (Dart) |
| State | Riverpod |
| Routing | GoRouter |
| Database | SQLite via sqflite |
| Security | flutter_secure_storage |
| Camera | camera plugin |
| Voice Recording | record plugin |
| Location | geolocator |
| Icons | HugeIcons |
| Fonts | Google Fonts (Inter) |
| Design System | Material 3 |

---

## Getting Started

### Prerequisites

- Flutter 3.41+
- Android device or emulator
- About 1GB free storage for the model file

### Build and Run

```bash
git clone https://github.com/thejohncaleb/resq.git
cd resq
flutter pub get
flutter run
```

### Setting Up the Gemma 4 Model

The app needs a Gemma model file to run on-device AI inference. The model file is approximately 500MB.

**Option 1: In-app Download**

When you first open the app, a bottom sheet will offer to download the model. Tap "Download" and wait for the download to complete. After download, restart the app.

The model downloads to your app storage. On restart, the native engine finds and loads it automatically.

**Option 2: Manual ADB Push**

If the in-app download doesn't work on your device (some devices restrict file access), you can push the model manually:

1. Download the Gemma model file to your computer
2. Connect your phone via USB
3. Run:
```bash
adb push model.bin /data/local/tmp/llm/model.bin
```
4. Restart the app

### Without a Model

The app works immediately without a model using a keyword-based classification system. It provides structured guidance for 14 emergency types. All features — camera, voice recording, guidance cards, medical summary, profile, history — work fully offline with no model.

---

## What Makes This Different

### AI is Invisible

Most AI apps shove a chatbot in your face. ResQ deliberately hides the AI. You interact with structured emergency cards, not a conversation. The model runs silently in the background. The output is parsed as JSON and rendered as clean, calm Material 3 components. This makes it feel like an emergency tool, not an AI demo.

### Offline by Design

No Firebase. No cloud APIs. No authentication. No login. No user accounts. SQLite for all data. Local JSON database of medical facilities sorted by GPS proximity. Everything works in airplane mode. This is not an afterthought — it is the founding constraint of the project. If it needs internet, it fails the people who need it most.

### Calm Under Pressure

Emergency apps must combat panic, not contribute to it. The design uses a muted teal and green colour palette. Red is reserved exclusively for medical warnings. Generous whitespace. Large typography. Large touch targets. One instruction per line. No unnecessary animations. Every design decision prioritises clarity over cleverness.

### Real Scenarios, Real Impact

Every feature was designed by thinking about real situations in and around Minna:

- A student bitten by a snake walking from night class at Gidan Kwano
- A student with a kitchen burn in their off-campus hostel, alone
- A farmer in a remote area of Niger State with no clinic within two hours
- A traveller attacked on an isolated road between villages
- A mother whose child has a severe allergic reaction with no pharmacy nearby

These are not edge cases. These are the people this app was built for.

---

## Hackathon Submission

- **Hackathon:** Build with Gemma: AI for Africa — Minna 2026
- **Track:** AI for Social Impact / Edge and Offline AI
- **Kaggle Notebook:** [ResQ — Offline Emergency Intelligence](https://www.kaggle.com/code/thejohncaleb/resq-offline-emergency-intelligence)
- **GitHub:** [github.com/thejohncaleb/resq](https://github.com/thejohncaleb/resq)

---

## Demo

The app flow in 30 seconds:

1. Home screen → tap the red emergency button
2. Camera opens → take a photo of the situation
3. "Tell me briefly what happened" → type or speak your description
4. Processing screen → multi-step progress
5. Flashcards → swipe through Assessment, Actions, Avoid, Monitor, Seek Care
6. Medical Summary → professional report ready for healthcare providers
7. Continue To Care → contacts, facilities, report sharing

---

## What I Would Build Next

- **Model fine-tuning** — fine-tune Gemma 4 on region-specific emergency protocols and local languages (Hausa, Yoruba, Nupe, Gbagyi)
- **SMS summaries** — auto-generate text message versions of medical summaries for areas with only basic phone coverage
- **Community facility updates** — crowd-sourced updates to the offline emergency facilities database
- **Wearable integration** — pull heart rate and SpO2 from smartwatches for richer vital sign data
- **Audio transcription** — use Gemma 4's native audio understanding for real-time voice-to-text during emergencies

---

## License

Apache 2.0

---

Built with late nights and a belief that technology should work where it is needed most.
