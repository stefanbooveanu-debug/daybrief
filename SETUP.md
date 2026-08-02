# DayBrief - Setup Guide for Another Laptop

## Prerequisites

You need these installed on the other laptop:

1. **Git** - https://git-scm.com/downloads
2. **Flutter SDK** - https://docs.flutter.dev/get-started/install
3. **Node.js** (for the server) - https://nodejs.org/
4. **Chrome browser** (for running the web app)

---

## Step 1: Clone the Repository

Open a terminal (PowerShell/CMD/Bash) and run:

```bash
git clone https://github.com/stefanbooveanu-debug/daybrief.git
cd daybrief
```

---

## Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

This downloads all packages defined in `pubspec.yaml`.

---

## Step 3: Set the Claude API Key (REQUIRED for AI features)

AI features call a local proxy in `server.js`, not Anthropic directly from the app. Set your Anthropic key in the environment before starting the server:

**PowerShell (Windows):**
```powershell
$env:ANTHROPIC_API_KEY = "your-anthropic-api-key"
node server.js
```

**macOS / Linux:**
```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"
node server.js
```

> **Note:** You no longer need `lib/config/app_config.dart`. Firebase config is already in the repo. AI buttons appear on web builds only (`flutter run -d chrome` or `flutter build web` + `node server.js`).

### Optional: Google Places (location autocomplete)

Location suggestions use Google Places through `server.js`. Create a Maps key in Google Cloud with **Places API** enabled, then:

```bash
export GOOGLE_MAPS_API_KEY="your-maps-api-key"
node server.js
```

Without this key, you can still type any location and open it in Google Maps; autocomplete suggestions will be empty.

During `flutter run -d chrome`, the app calls `http://127.0.0.1:8080/api/places/*`, so keep `node server.js` running.

---

## Step 4: Run the App

### Option A: Development Mode (with hot reload)

```bash
flutter run -d chrome
```

The app opens in Chrome and stays up while the terminal is running.

### Option B: Production Build + Server (faster, more stable)

Build once:
```bash
flutter build web --release
```

Then run the server:
```bash
node server.js
```

Open in browser: http://localhost:8080

---

## Step 5: Firebase Console Setup

The Firebase project (`daybrief-d6bf6`) is already configured in the code. Make sure these are enabled in the Firebase Console:

1. Go to https://console.firebase.google.com/project/daybrief-d6bf6
2. **Authentication** → Sign-in method → Enable "Email/Password"
3. **Firestore Database** → Make sure rules allow authenticated users to read/write

Example permissive rules (for development only):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Common Issues

### "Module not found" when running `node server.js`
Make sure you're in the `daybrief` folder, not its parent.

### Flutter web not enabled
Run: `flutter config --enable-web`

### Chrome not found by Flutter
Make sure Chrome is installed and in your PATH.

### Firebase initialization error
Check that `lib/firebase_options.dart` exists with the real config (it should be in the repo).

---

## File Locations

- **Source code**: `lib/`
- **Built web app**: `build/web/` (after `flutter build web`)
- **Server script**: `server.js` (Node.js, no extra dependencies needed)
- **API key**: set `ANTHROPIC_API_KEY` before running `node server.js`
- **Firebase config**: `lib/firebase_options.dart` (already in repo)

---

## Quick Start Commands (All-in-One)

```bash
# Clone and setup
git clone https://github.com/stefanbooveanu-debug/daybrief.git
cd daybrief
flutter pub get

# Set ANTHROPIC_API_KEY, then build and run
flutter build web --release
node server.js
```

Then open http://localhost:8080
