ResQ — On-Device Emergency Intelligence Powered by Gemma 4
Team: THEJOHNCALEB
Track: AI for Social Impact / Edge and Offline AI
Repository: github.com/THEJOHNCALEB/resq
Model: Gemma 4 E2B (litert-community/gemma-4-E2B-it-litert-lm)

What is ResQ?
ResQ is an on-device emergency intelligence companion built for the moments between an incident and professional medical care. It uses Gemma 4 E2B to analyse emergency situations — combining camera images, voice recordings, and text — then provides calm, structured guidance in five colour-coded cards. Everything happens on the device. Nothing leaves the phone.

ResQ is not a chatbot. It is not a symptom checker. It is an emergency tool designed for rural communities where internet connectivity and immediate healthcare are unavailable.

The Problem
It is 9 PM at FUTMinna. A student walks back from night class at Gidan Kwano campus. A snake bites his ankle. The university clinic is closed. The nearest hospital is 45 minutes away. His phone has no signal.

In rural Nigeria, emergency medical care is often hours away. A farmer bitten by a snake. A mother whose child has a severe allergic reaction in a village with no clinic. A student who burns themselves cooking in a hostel with no first aid training. In these critical minutes, panic leads to harmful actions — tourniquets on snake bites, butter on burns, moving fracture victims incorrectly — that cause permanent harm.

Existing solutions need internet, which is the first thing to go in these situations. ChatGPT cannot help when there is no signal.

Why Gemma On-Device?
The decisive question for any Gemma project is: "Why not just paste this into ChatGPT?"

ResQ's answer is unanswerable: when you are bitten by a snake on a dark road with no signal, no cloud AI can reach you. Processing on-device is not a feature — it is the entire reason the app exists. Your emergency data never leaves your hands.

We chose Gemma 4 E2B specifically because:

It fits on a phone. The 2.4GB LiteRT-LM model runs on mid-range Android devices with 4GB+ RAM.
It is multimodal. Camera images of injuries and voice descriptions are analysed together. The vision encoder processes what it sees. The language model reasons about what is described. Text-only models cannot do this.
It reasons, not scripts. Follow-up questions are dynamically reasoned by the model — snake bites generate different questions than burns. No hardcoded decision trees.
Architecture: The Split of Responsibility
The core design decision: structured UI owns the experience; Gemma owns understanding.

What deterministic code does (never the model):
Render five colour-coded guidance cards from structured JSON
Store encrypted medical profiles via flutter_secure_storage
Calculate GPS proximity to nearby facilities from a local JSON database
Record audio and capture camera images
Format and display medical summaries for healthcare providers
Save complete emergency session timelines to SQLite
What Gemma does (only the model can):
Analyse camera images and voice recordings together via the vision encoder
Determine emergency type and severity from multimodal input
Generate structured JSON with assessment, actions, avoid, monitor, and seekCare
Write professional medical summaries for healthcare providers
Dynamically reason about what follow-up questions to ask
This split means the guidance format is always clean and structured. The UI is never raw AI text. Every prompt forces JSON output through five specialised templates:

Emergency Analysis → {"type", "severity", "context", "nextQuestion"}
Guidance Generation → {"assessment", "actions", "avoid", "monitor", "seekCare"}
Medical Summary    → Professional healthcare narrative

Technical Implementation
On-Device Inference Pipeline
We use flutter_gemma (v1.3.0) with the flutter_gemma_litertlm engine for native LiteRT-LM inference. The engine is initialised at startup via FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]). The ~2.4GB model downloads on first launch from Hugging Face with progress tracking and comforting messages.

One-shot inference: We use createSession() + getResponse() rather than createChat() + generateChatResponse(). This follows the winning approach from Chapaa (GDG Embu) — sessions are faster for single-pass inference. Temperature is set to 0.0 with topK=1 for deterministic guidance.

Multimodal pipeline: The emergency analysis receives actual image bytes via Message.withImage() — not text descriptions. Camera photos of injuries are passed directly to Gemma 4's vision encoder alongside the voice recording and typed description. Vision modality is enabled per-session via enableVisionModality: true.

Cached model loading: The model is loaded once at startup with a 90-second timeout and stored in memory. All subsequent inference calls reuse the same loaded instance — no reloading between screens.

Frameworks
Inference: flutter_gemma (v1.3.0) + flutter_gemma_litertlm
App: Flutter 3.44, Dart 3.12, Riverpod (state), GoRouter (navigation)
Storage: SQLite (sqflite) for history, flutter_secure_storage for encrypted profiles
UI: Material 3, HugeIcons, bundled Inter font
Offline: PrivacyMonitor (live HTTP counter), local JSON facilities database

Privacy: Proof, Not a Promise
Privacy is not a checkbox — it is the measurable signature of the app:

Zero network requests after download. A PrivacyMonitor singleton intercepts all HTTP via HttpOverrides on native and fetch patching on web. The privacy seal on-screen is a live counter showing "0 outbound" — a measurement, not a badge.
No cloud fonts. We removed google_fonts entirely and bundled Inter as a local asset. A Google Fonts runtime fetch would have made the "0 requests" seal a lie.
No real data in the repo. .gitignore blocks *.task, *.bin, *.litertlm, *.m4a, and config.json.
The demo moment: Open Android devtools and verify zero traffic. That is the pitch.

UI: Calm Under Pressure
The design language is built around calmness under pressure. Muted teal palette. Red reserved exclusively for medical warnings. Large typography. Generous whitespace. One instruction per line. No unnecessary animations.

Key screens:
Home: A large red emergency button centered on screen with a subtle pulse animation. Privacy counter ("0 outbound") in the top corner. Bottom navigation with Profile, Home, and History tabs.
Emergency Flow: Camera opens immediately. User takes a photo or uploads from gallery, then types or records a voice description. Continue navigates directly to guidance.
Guidance Cards: Five full-width colour-coded cards stacked seamlessly — Assessment (blue), Immediate Actions (teal), Things To Avoid (coral), Monitor (amber), When To Seek Care (purple). No border radius, no gaps. A "Find Hospitals" card with map overlay opens Google Maps to search for nearby hospitals.
Medical Summary: AI-generated report with markdown rendering, formatted for healthcare providers. Continue to Care screen with emergency contacts, report sharing, and nearby facilities sorted by GPS.
Care History: Complete timeline of all past emergency sessions with descriptions, dates, and full detail views.

Challenges & Solutions
Flutter SDK upgrade: flutter_gemma 1.3.0 requires Dart 3.12+. Our Flutter was on 3.41.9 (Dart 3.11.5). Upgrading to Flutter 3.44.8 mid-sprint was risky but necessary for Gemma 4 multimodal support. All 54 package dependencies resolved successfully.

Model path on Android: flutter_gemma 0.1.x hardcoded the model path to /data/local/tmp/llm/ which is permission-restricted on many devices. The 1.x API solves this with FlutterGemma.installModel().fromFile() — the model loads from any writable application path. No root required.

Session vs Chat API: Our initial implementation used createChat() + generateChatResponse() which was significantly slower. Pivoted to createSession() + getResponse() after studying the winning Chapaa (GDG Embu) project. Session-based inference is 40-60% faster for one-shot prompts.

Multimodal input: Getting camera, voice, and text to work reliably in a single emergency flow required careful state management. Recording was initially silent — fixed by adding explicit sample rate (44100) and channel configuration (mono).

Offline font loading: google_fonts makes a runtime network request on first launch, which would break our "0 outbound" privacy claim. We downloaded Inter TTF files from Google Fonts CSS API, bundled them as local assets, registered in pubspec.yaml, and removed the google_fonts package entirely.

Real image analysis: Our initial implementation only passed text descriptions to Gemma. Passing actual Uint8List image bytes via Message.withImage() and enabling enableVisionModality on the session allowed the model to correctly correlate visible injuries with the voice description.

What Makes ResQ Different
Most AI apps shove a chatbot in your face. ResQ deliberately hides the AI — users interact with colour-coded emergency cards, not conversations. The guidance is calm, structured, and designed to combat panic.

The multimodal analysis is genuine Gemma 4 usage — camera + voice + text analysed together. The privacy claim is measured, not promised: a live HTTP counter proves zero outbound requests after model download. The app works where it matters most — with no internet, no cloud, no accounts.

For a student bitten by a snake on the way from night class at FUTMinna, ResQ turns a moment of panic into a moment of clarity.

Built for Build with Gemma: AI for Africa — FUTMinna 2026
