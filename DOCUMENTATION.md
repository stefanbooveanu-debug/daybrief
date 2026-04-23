# DayBrief - Development Documentation

**Voice-activated calendar and schedule assistant built with Flutter**

Repository: https://github.com/stefanbooveanu-debug/daybrief.git

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Development History](#development-history)
5. [Session Changelog](#session-changelog)
6. [Setup & Installation](#setup--installation)
7. [Configuration](#configuration)

---

## Overview

DayBrief is a Flutter-based calendar/schedule application with voice assistance, AI-powered event parsing, and multiple calendar views. The app supports web, desktop, and mobile platforms.

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Storage**: SharedPreferences (web-compatible)
- **AI**: Anthropic Claude API (claude-3-5-sonnet)
- **Voice**: speech_to_text, flutter_tts
- **Auth**: Firebase Auth (+ Demo mode)
- **Calendar Sync**: Google Calendar API

---

## Features

### Core Features
- **Multiple Views**: Day / Week / Month calendar views
- **Event Management**: Add, edit, delete, complete events
- **Categories**: Work, Personal, Health, Social, Shopping with custom colors
- **Search**: Full-text search across events
- **Dark Mode**: System-wide theme toggle with smooth transitions
- **Multi-language**: English interface

### Advanced Features
- **AI Quick Add**: Natural language event parsing via Claude AI
- **AI Daily Summary**: Smart briefing of your day's schedule
- **Voice Assistant**: Voice commands and audio responses (TTS)
- **Driving Mode**: Voice-only safe mode for driving
- **Demo Mode**: Free-pass access without signup
- **Calendar Sync**: Google Calendar import/export
- **Family Calendar**: Shared events with family members
- **Quick Poll**: Find the best meeting time
- **Voice Templates**: Custom voice commands
- **Share Calendar**: Share events via iCal
- **Time Reports**: Weekly time analysis by category
- **Smart Reminders**: Notifications 1 hour before events
- **Recurring Events**: Daily, weekly, monthly, yearly patterns

---

## Architecture

### Directory Structure

```
lib/
├── config/
│   └── app_config.dart          # API keys (gitignored)
├── models/
│   ├── event.dart               # Event data model
│   └── voice_template.dart
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── event_provider.dart      # Events state
│   ├── voice_provider.dart      # Voice assistant state
│   └── voice_template_provider.dart
├── screens/
│   ├── auth_screen.dart         # Login/Signup (with Demo Mode)
│   ├── home_screen.dart         # Main day view
│   ├── week_view_screen.dart
│   ├── month_view_screen.dart
│   ├── settings_screen.dart
│   ├── search_screen.dart
│   ├── driving_mode_screen.dart
│   ├── time_report_screen.dart
│   ├── family_calendar_screen.dart
│   ├── share_calendar_screen.dart
│   ├── quick_poll_screen.dart
│   ├── calendar_sync_screen.dart
│   └── voice_templates_screen.dart
├── services/
│   ├── claude_service.dart      # Claude AI integration
│   ├── database_service.dart    # Storage (SharedPreferences)
│   ├── speech_service.dart      # STT
│   ├── voice_command_service.dart
│   ├── google_calendar_service.dart
│   └── firebase_service.dart
├── utils/
│   └── date_utils.dart          # Cached DateFormatters
├── widgets/
│   ├── add_event_sheet.dart     # Event creation (with AI)
│   ├── event_card.dart
│   ├── voice_assistant_button.dart
│   └── animated_theme.dart
├── theme/
│   └── app_theme.dart
└── main.dart                     # App entry point
```

### State Management

- `AuthProvider` - User authentication and demo mode
- `EventProvider` - Event CRUD operations with in-memory cache
- `VoiceProvider` - Voice assistant state (listening/speaking)
- `VoiceTemplateProvider` - Custom voice command templates

---

## Development History

The app was developed in multiple phases:

### Phase 1: Foundation (Initial commits)
- Set up Flutter project structure
- Voice-activated calendar base
- Firebase configuration
- Basic web setup

### Phase 2: UI Overhaul
- Google Calendar-style UI
- Dark mode support
- Category color system
- Month/Week views
- Search functionality
- Smooth animations

### Phase 3: Feature Expansion
- Voice assistant with natural TTS
- Smart reminders
- Mark complete with strikethrough
- Persistent category colors
- Glassmorphism auth UI
- Unit tests

### Phase 4: Advanced Features
- Recurring events
- Location + Maps integration
- Event editing
- Calendar sync with Google Calendar
- Event sharing (iCal)
- Copy to clipboard

### Phase 5: Backend Integration
- Firebase Auth with real credentials
- Firestore for events
- Google Calendar API service
- Multiple calendars (Work/Personal/Family)
- Voice templates

### Phase 6: Persistence & Platforms
- SQLite for offline-first storage
- TTS web compatibility
- Driving mode (voice-only)

### Phase 7: Refactor & Polish (Recent)
- Fixed compilation errors
- API alignment between screens/providers
- Locale initialization for date formatting
- Theme toggle fixes

---

## Session Changelog

Recent changes from this session (most recent first):

### `6e8e3c5` - Smooth dark mode toggle
**Date:** Latest
**Summary:** Delayed theme change 250ms so the Switch animation completes before the entire app rebuilds. Result: smoother toggle.

### `edd1598` - Fix AI input visibility + web storage
**Changes:**
- Added semi-transparent background to AI input field (was white text on white)
- Full dark mode support for AddEventSheet
- **Replaced SQLite with SharedPreferences** (SQLite doesn't work on web browsers)
- Events now persist properly across sessions

### `950fc85` - Claude AI Integration
**Added:**
- `lib/services/claude_service.dart` - Claude AI API client
- AI Quick Add in event sheet (purple gradient box)
  - Parses natural language: *"Meeting tomorrow at 3pm"* → Event
- AI Daily Summary button (sparkle icon in header)
  - Generates friendly daily briefing
- `lib/config/app_config.dart` - API keys (gitignored)
- Methods: `parseEventFromText()`, `generateDailySummary()`, `answerQuestion()`, `getSmartSuggestions()`

### `ae4ceaa` - Performance optimizations
**Changes:**
- Created `lib/utils/date_utils.dart` - centralized cached DateFormat instances
- Added `cacheExtent: 200` to ListView.builder for smoother scrolling
- EventCard uses static cached formatters to avoid recreation on every build

### `d2d4024` - Language change + Demo Mode
**Changes:**
- Translated entire UI from Romanian to English
  - "Zi/Săptămână/Lună" → "Day/Week/Month"
  - "Bună dimineața" → "Good morning"
  - "Azi" → "Today"
  - "Utilizator" → "User"
- Added **Demo Mode** button to auth screen
  - One-click access without signup
  - New `signInDemo()` method in AuthProvider
  - `isDemoMode` flag

### `fc0b3b0` - Theme toggle fix + locale fallbacks
- Theme toggle now actually persists after navigating back
- Added multiple locale fallbacks (en_US)

### `da8cc20` - Locale initialization
- Fixed `LocaleDataException` by initializing `date_symbol_data_local`
- Added `initializeDateFormatting('ro_RO')` in main

### `4365099` - Compilation fixes
**Major API alignment between screens and providers:**
- HomeScreen: Added optional constructor params (`categoryColors`, `onCategoryColorsChanged`, `onThemeChanged`)
- Fixed method names: `getEventsForDate()` → `getEventsForDay()`
- Fixed method names: `loadEvents()` → `refreshEvents()`
- Changed `AnimatedThemeWrapper` → `SmoothThemeTransition`
- Fixed `AddEventSheet` parameter: `selectedDate:` → `initialDate:`
- Made various screens' params optional
- Added missing packages to `pubspec.yaml`: `url_launcher`, `google_sign_in`, `http`, `file_picker`, `share_plus`
- Fixed Event model with `location` and `RecurrenceType`
- Fixed GoogleCalendarService

### `400f52f` - DrivingModeScreen
- Added voice-only safe mode for driving
- Accessible from settings

### `0de1e5a` - Theme initState fix
- Moved `Theme.of(context)` from `initState` to `didChangeDependencies`

---

## Setup & Installation

### Prerequisites
- Flutter SDK (3.x+)
- Dart SDK
- Chrome (for web), or Android/iOS emulator

### Install Dependencies

```bash
cd daybrief
flutter pub get
```

### Run the App

**Web (Chrome):**
```bash
flutter run -d chrome
```

**Desktop (Windows):**
```bash
flutter run -d windows
```

**Mobile:**
```bash
flutter run -d android
flutter run -d ios
```

### Build for Production

**Web:**
```bash
flutter build web
```

**Android APK:**
```bash
flutter build apk
```

---

## Configuration

### API Keys

**⚠️ Important:** The `lib/config/app_config.dart` file is gitignored. You need to create it locally:

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String anthropicApiKey = 'YOUR_CLAUDE_API_KEY';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-3-5-sonnet-20241022';
  static const int maxTokens = 1024;
}
```

### Firebase (Optional)
Configure `lib/firebase_options.dart` if using Firebase Auth/Firestore.

### Google Calendar (Optional)
Uses OAuth2 via `google_sign_in` package. Set up OAuth credentials in Google Cloud Console.

---

## Known Issues

- **Web:** SQLite not supported - uses SharedPreferences instead (implemented)
- **Speech_to_text:** `cancelOnError` deprecation warning (non-blocking)

---

## Future Work

From the brainstorming session:

### Remaining UI/UX
- [ ] Custom color picker (currently preset colors)
- [ ] Illustrated empty states
- [ ] Pull to refresh
- [ ] Haptic feedback

### Remaining AI Features
- [ ] Smart voice assistant (ask Claude about schedule)
- [ ] Smart suggestions (pattern detection)
- [ ] Calendar conflict resolution

### Remaining Integrations
- [ ] Real Firebase Auth (currently mock)
- [ ] Push notifications
- [ ] Cloud sync across devices

---

## License & Contact

Created by DayBrief Team  
Version: 1.0.0
