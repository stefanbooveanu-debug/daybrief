# VoiceCal Setup Guide

## Firebase Setup (Required)

Follow these steps to connect your app to Firebase:

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and name it "VoiceCal"
3. Disable Google Analytics (optional) and click Create

### 2. Enable Authentication
1. In your Firebase project, go to **Build > Authentication**
2. Click "Get started"
3. Under "Sign-in method", enable **Email/Password**
4. Save the settings

### 3. Enable Firestore Database
1. Go to **Build > Firestore Database**
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to you
5. Click "Enable"

### 4. Add Android App to Firebase
1. Go to **Project Settings** (gear icon)
2. Under "Your apps", click the Android icon
3. Enter:
   - Android package name: `com.voiscal.voice_cal`
   - App nickname: `VoiceCal`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in: `android/app/google-services.json`

### 5. For iOS (if building for iOS)
1. Click the iOS icon in Firebase console
2. Enter your iOS bundle ID
3. Download `GoogleService-Info.plist`
4. Add it to your iOS project via Xcode

## Building the App

### Android
```bash
cd voice_cal
flutter build apk --debug
```

The APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

### iOS
```bash
cd voice_cal
flutter build ios
```

## Testing the Voice Feature

The voice assistant uses "Hey VoiceCal" as the wake word:
- Say: **"Hey VoiceCal, what do I have today?"**
- Say: **"Hey VoiceCal, add barber at 3pm"**

## Troubleshooting

### Microphone Permission Denied
Make sure to grant microphone permission when prompted on Android.

### Speech Recognition Not Working
- Ensure internet connection (required for speech recognition)
- Check device has a microphone
- Try speaking clearly in English

### Firebase Connection Error
- Verify `google-services.json` is in the correct location
- Check the package name matches exactly: `com.voiscal.voice_cal`
