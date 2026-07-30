# ResQ: Offline Emergency Intelligence with Gemma 4

## Build with Gemma: AI for Africa Hackathon -- FUTMinna 2026

**Track:** AI for Social Impact / Edge and Offline AI

---

## Problem Statement

It is 9 PM at the Federal University of Technology, Minna (FUTMinna). A student is walking back from night class at the Gidan Kwano campus. The path from the lecture halls to the hostels passes through bushland. He feels a sharp pain in his ankle. A snake slithers away into the grass. The university clinic is closed. The nearest hospital is 45 minutes away. His leg is swelling, the pain is spreading, and he has no idea what to do.

In rural Africa, emergency medical care is often hours away. A farmer bitten by a snake in a remote field. A mother whose child has a severe allergic reaction in a village with no clinic. A student who burns themselves cooking in a hostel with no first aid training. A traveller attacked on an isolated road.

In these situations, the minutes between the incident and professional care are critical. Yet most people have no guidance during this window. Internet connectivity is unreliable or non-existent. Healthcare facilities may be closed or distant. Panic leads to harmful actions: applying tourniquets for snake bites, butter on burns, or moving fracture victims incorrectly.

ResQ solves this by bringing **offline AI emergency guidance** to any Android device, powered entirely by **Gemma 4 E2B** running on-device.

---

## Solution: ResQ

ResQ is an offline-first emergency intelligence companion. It runs entirely on-device -- no backend, no cloud APIs, no authentication, no internet required. The application is deliberately **not a chatbot** and **not a symptom checker**. Instead, it intelligently guides users through emergencies using structured, calm, easy-to-follow information cards. The AI is invisible.

### Core Flow

1. User taps **Start Emergency**
2. Camera opens immediately -- user captures an image of the situation
3. User speaks or types: "Tell me briefly what happened"
4. Gemma 4 analyses both the image (vision encoder) and the voice transcription (text)
5. Gemma 4 generates a structured assessment and dynamically reasons about exactly the minimum number of follow-up questions needed -- never a hardcoded decision tree
6. Instead of chat bubbles, users see five structured guidance cards:

| Section | Purpose |
|---|---|
| **Current Assessment** | What we understand about the situation |
| **Immediate Actions** | Step-by-step actions to take now |
| **Things To Avoid** | Critical mistakes to prevent |
| **Monitor** | Signs to watch for changes |
| **When To Seek Immediate Medical Care** | Red flags requiring urgent professional help |

7. After guidance, Gemma 4 generates a **professional medical summary** -- formatted for healthcare providers, including timeline, symptoms, visible findings, actions taken, and AI assessment
8. The **Continue To Care** screen provides: medical summary review, emergency contact calls, report sharing, and a list of nearby medical facilities sorted by GPS proximity (loaded from a local JSON database when offline)

### Medical Profile

Users store an encrypted local profile (name, age, blood group, allergies, medications, conditions, emergency contacts) used by Gemma 4 to personalise guidance and enrich the medical summary.

### Care History

Every emergency session is saved locally with its complete timeline, images, guidance, and summary -- accessible for healthcare follow-up.

---

## How We Used Gemma 4

### Model Selection

We selected **Gemma 4 E2B** (2.4B parameters, multimodal) for three reasons:

1. **Multimodal capability** -- ResQ captures both camera images and voice input simultaneously. Gemma 4's vision encoder processes injury images (burns, wounds, swelling, bite marks) while its language model reasons about the voice description, creating an integrated assessment impossible with text-only models.

2. **Edge deployment** -- At 2.4B parameters with bfloat16 precision, Gemma 4 E2B runs efficiently on mobile devices via LiteRT, enabling true offline operation. Rural users with no internet access get the same quality of guidance as connected users.

3. **Native reasoning for dynamic questions** -- The follow-up question system uses Gemma 4's reasoning capabilities rather than hardcoded decision trees. The model actively determines what additional information it needs to provide better guidance -- how large is the swelling? Can you describe the snake? Are you having difficulty breathing?

### Prompt Engineering Architecture

The key innovation is our **structured output pipeline** -- five specialised prompt templates that force Gemma 4 to produce JSON-structured responses rather than conversational text:

```
Emergency Analysis => {"type", "severity", "context", "nextQuestion"}
Guidance Generation => {"assessment", "actions", "avoid", "monitor", "seekCare"}
Medical Summary   => Professional narrative for healthcare providers
Follow-up         => Single most important question (dynamically reasoned)
```

This architecture ensures:
- **Deterministic parsing** -- JSON output is programmatically extractable for UI rendering
- **Invisible AI** -- users never see raw model output, only structured guidance cards
- **Calm UX** -- short, simple instructions with generous whitespace and large touch targets
- **Reliability** -- consistent output format, with a keyword-based fallback engine when the model is unavailable

### Implementation

In the Flutter application (`lib/shared/services/gemma_service.dart`), Gemma 4 is accessed through `flutter_gemma` with LiteRT for on-device inference. The service includes a graceful fallback system: if the model is not loaded, keyword-based emergency classification provides basic guidance. This ensures the app functions even before the model is downloaded.

The Kaggle notebook demonstrates the complete prompt pipeline running on Gemma 4 E2B with two real emergency scenarios: a FUTMinna night-class student bitten by a snake, and a kitchen burn with multimodal image analysis.

---

## Why This Matters for Africa

**Healthcare accessibility:** The WHO estimates that half the world's population lacks access to essential health services. In sub-Saharan Africa, the ratio of doctors to patients can be as low as 1:10,000. Emergency response times in rural areas can exceed 2 hours.

**Connectivity reality:** Only 28% of sub-Saharan Africa's population uses mobile internet. Even where coverage exists, data costs are prohibitive for many. An online-dependent solution would fail the very people who need it most.

**Language diversity:** Africa has over 2,000 languages. ResQ's voice input and multimodal approach (image + voice) reduces language barriers -- an image of an injury is universally understood regardless of the language spoken.

**Real scenarios from FUTMinna and beyond:**
- A student bitten by a snake walking from night class at Gidan Kwano campus knows to immobilise the limb, not apply a tourniquet, and call for help
- A farmer in rural Niger bitten in the field knows to keep calm, remove jewellery near the bite, and seek antivenom
- A student with a kitchen burn in their off-campus hostel knows to cool it under water for 20 minutes, not apply butter or ice
- A mother whose child has an allergic reaction recognises throat tightness as a critical sign requiring immediate evacuation
- A traveller attacked on a road between villages knows to assess injuries systematically and contact emergency services

---

## Technical Architecture

```
Flutter (Dart)                         Python (Kaggle Notebook)
+------------------------+            +---------------------------+
|  UI: Material 3        |            |  Gemma 4 E2B              |
|  State: Riverpod       |            |  via keras_hub            |
|  Routing: GoRouter     |            |                           |
+------------------------+            |  Prompt Pipeline:         |
|  GemmaService          |<-- Same -->|  - Emergency Analysis     |
|  flutter_gemma         |   Prompts  |  - Guidance (JSON)        |
|  LiteRT Engine         |            |  - Follow-up Questions    |
+------------------------+            |  - Medical Summary        |
|  SQLite (sqflite)      |            |                           |
|  Secure Storage        |            |  Full pipeline demo       |
|  Local Facilities JSON |            |  with fallback analysis   |
+------------------------+            +---------------------------+
```

- **State Management:** Riverpod (compile-safe, testable)
- **Routing:** GoRouter (declarative navigation)
- **Database:** SQLite via sqflite (profile encrypted with flutter_secure_storage)
- **AI:** flutter_gemma + LiteRT for on-device Gemma 4 inference
- **Design:** Material 3 with a muted teal palette (calming, professional), Google Fonts (Inter)
- **Architecture:** Clean Architecture, feature-first folder structure
- **Code quality:** 29 Dart files, zero lint errors on flutter analyze

---

## What We Built in This Sprint

1. A complete Flutter application (29 Dart files, zero lint errors) with full offline emergency flow
2. A Kaggle notebook demonstrating the Gemma 4 prompt pipeline with two real Minna scenarios
3. A keyword-based fallback engine ensuring the app works without a loaded model
4. Structured prompt engineering that forces JSON output for reliable UI rendering
5. Dynamic follow-up questions reasoned by Gemma 4 -- no hardcoded decision trees

---

## What's Next

1. **Model fine-tuning** -- Fine-tune Gemma 4 on region-specific emergency protocols and local languages (Hausa, Yoruba, Nupe, Gbagyi)
2. **Community facility database** -- Crowd-sourced updates to the offline emergency facilities JSON for Niger State
3. **SMS integration** -- Auto-generate SMS medical summaries for areas with only basic phone coverage
4. **Wearable integration** -- Pull heart rate and SpO2 data from wearable devices for richer vital sign assessments
5. **Gemma 4 E4B upgrade** -- Use the larger 4.3B model for more detailed guidance on higher-end devices
