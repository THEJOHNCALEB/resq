# Submission Instructions -- ResQ

## Build with Gemma: AI for Africa Hackathon -- FUTMinna 2026

**Deadline:** Aug 3, 2026 at 12:00 AM GMT+1
**Track:** AI for Social Impact (or Edge and Offline AI)

---

## Submission Requirements (3 Pieces)

The Kaggle Writeup is the main submission. Inside it, you attach links for:

* Code repository
* Live demo (notebook + optional video)

**The Writeup is the container.** You write the report, then attach the repo link, notebook link, and video link inside it. None of them are submitted separately.

| Requirement | What to submit | Where |
|---|---|---|
| **Kaggle Writeup** | The written project report (text, 1500-word limit) | Kaggle Writeup editor |
| **Public Code Repository** | Link to the Flutter app source code | Attached to the Writeup as a link |
| **Live Demo** | Kaggle Notebook (runnable) + App demo video (optional but recommended) | Both attached to the Writeup as links |

**The Writeup is the container.** You write the report, then attach the repo link, notebook link, and video link inside it. You do NOT submit them as separate entries -- they are links inside the Writeup.

---

## How the Pieces Connect

```
Kaggle Writeup (your report)
    |
    +-- Text: problem, solution, how you used Gemma 4, architecture, impact
    |
    +-- Attachment: GitHub Repo URL
    |       Contains the Flutter app source code (29 Dart files)
    |       Judges verify the code is real and uses Gemma 4
    |
    +-- Attachment: Kaggle Notebook URL
    |       Runnable notebook demonstrating Gemma 4 with real emergency scenarios
    |       Judges can click Run All and see the pipeline produce structured output
    |
    +-- Attachment: App Demo Video URL (YouTube unlisted)
            Screen recording of the Flutter app in action
            Shows home screen, emergency flow, guidance cards, medical summary
```

The notebook is NOT the writeup. The writeup is NOT the code repo. They are three separate things connected by links in the Writeup.

---

## Step 1: Upload the Kaggle Notebook (Live Demo)

The notebook demonstrates Gemma 4 E2B running the full ResQ emergency pipeline.

### Create the Notebook

1. Go to https://www.kaggle.com/code
2. Click **New Notebook**
3. In the notebook editor, click **File > Upload notebook**
4. Upload `docs/kaggle_notebook.py` from this project
5. Kaggle will auto-convert it to notebook cells

### Notebook Settings

- **Accelerator:** GPU T4 x2 or GPU P100 (Gemma 4 12B needs ~24GB VRAM; E2B variant needs ~5GB)
- **Environment:** Default Python (includes kagglehub, transformers, torch)
- **Internet:** ON (required to download the model on first run)

### Model Paths (from google/gemma-4 on Kaggle Models)

The notebook uses two model variants, trying 12B first, falling back to E2B:

| Variant | Kaggle Path | Size |
|---|---|---|
| 12B Unified | `google/gemma-4/transformers/gemma-4-12b` | ~24GB |
| E2B | `google/gemma-4/transformers/gemma-4-e2b` | ~5GB |

Both use the official `AutoProcessor` + `AutoModelForCausalLM` API.

### Get the Notebook URL

1. Run all cells (Runtime > Run All)
2. Wait for model download (takes a few minutes on first run)
3. Save the notebook
4. Copy the URL from your browser address bar

---

## Step 2: Upload the Flutter Code Repository

This is the "Source of Truth" -- judges verify you actually built the thing using Gemma 4.

### Option A: GitHub (Recommended)

```bash
cd /path/to/resq
git init
git add .
git commit -m "ResQ: Offline Emergency Intelligence with Gemma 4 -- FUTMinna 2026"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/resq.git
git push -u origin main
```

Make sure the repo is **public**. Copy the GitHub URL.

### Option B: Kaggle Dataset

1. Zip the entire `resq/` directory
2. Go to https://www.kaggle.com/datasets > New Dataset
3. Upload the zip file
4. Set visibility to Public
5. Copy the dataset URL

---

## Step 3: Create the Kaggle Writeup (The Report)

The writeup content is ready in `docs/KAGGLE_WRITEUP.md`.

### Steps

1. On the hackathon page, click **New Writeup**
2. **Title:** `ResQ: Offline Emergency Intelligence with Gemma 4`
3. **Subtitle:** `On-device multimodal AI for emergency response in rural Nigeria`
4. **Select Track:** "AI for Social Impact"
5. Copy the content from `docs/KAGGLE_WRITEUP.md` and paste into the editor
6. Format sections as Kaggle Writeup sections (use the formatting toolbar)

### Attach Resources

Scroll to the **Attachments** section in the Writeup editor:

1. Add a **Project Link**:
   - Label: `Code Repository`
   - URL: Your GitHub or Kaggle Dataset URL (from Step 2)

2. Add a **Project Link**:
   - Label: `Live Demo (Gemma 4 Notebook)`
   - URL: Your Kaggle Notebook URL (from Step 1)

### Optional: App Demo Video (Highly Recommended)

This gives judges a direct look at the Flutter app. Record 30-60 seconds:

1. Open the app -- show the calm home screen
2. Tap "Start Emergency" -- show the camera opening
3. Show the voice input prompt ("Tell me briefly what happened")
4. Demonstrate the structured guidance cards (5 sections)
5. Show the medical summary being generated
6. Show the Continue To Care screen with facility list

Upload to YouTube as **unlisted** (or Google Drive with "anyone with link") and add as a Project Link labeled "App Demo Video".

---

## Step 4: Submit

1. Review your Writeup -- ensure:
   - [ ] Writeup content is complete (under 1500 words)
   - [ ] Code Repository link is attached and the repo is public
   - [ ] Live Demo (Notebook) link is attached
   - [ ] Track is selected (AI for Social Impact)
2. Click the **Submit** button (top right corner of the Writeup editor)
3. You can unsubmit, edit, and resubmit any time before the deadline

---

## Quick Checklist

| Item | Status |
|---|---|
| Kaggle Notebook uploaded and runs | [ ] |
| Code repo pushed and public | [ ] |
| Writeup written with all sections | [ ] |
| Both links attached to Writeup | [ ] |
| Track selected (AI for Social Impact) | [ ] |
| Submitted before Aug 3, 12:00 AM GMT+1 | [ ] |

---

## File Reference

| File in this repo | What it is |
|---|---|
| `docs/KAGGLE_WRITEUP.md` | Writeup content (copy to Kaggle Writeup editor) |
| `docs/kaggle_notebook.py` | Notebook to upload to Kaggle (the Live Demo) |
| `docs/SUBMISSION.md` | This file -- instructions |
| `README.md` | GitHub repo README (judges see this on the repo) |
| `lib/shared/services/gemma_service.dart` | Gemma 4 prompt engineering implementation |
| `lib/features/emergency/` | Emergency flow UI (camera, voice, guidance) |
| `assets/data/emergency_facilities.json` | Offline facilities database |
