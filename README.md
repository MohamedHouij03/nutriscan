# 🥗 NutriScan NER

> AI-powered allergen and harmful additive detector from ingredient list photos.

---

## 📱 Overview

**NutriScan NER** is a production-ready Flutter application that:

1. Uses the **camera** to scan a food label or ingredient list
2. Extracts text via **Google ML Kit OCR**
3. Sends extracted text to an **AI API (Mistral/OpenAI)** using Named Entity Recognition (NER)
4. Detects **allergens** (milk, gluten, peanuts, etc.) and **harmful additives** (E102, E220, etc.)
5. Displays structured results with severity levels
6. Saves scan history to **Firebase Firestore** with offline fallback

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/        # Colors, text styles, theme, app constants
│   ├── errors/           # Typed exceptions and failures
│   ├── router/           # GoRouter + splash screen
│   ├── services/         # OCR, NER API, connectivity, logger
│   └── utils/            # AppUtils helpers
│
├── features/
│   ├── auth/
│   │   ├── data/         # AuthRemoteDataSource (Firebase Auth)
│   │   ├── domain/       # AuthRepository (Either<Failure,T>)
│   │   └── presentation/
│   │       ├── providers/ # AuthNotifier (StateNotifier)
│   │       └── screens/   # LoginScreen, SignupScreen
│   │
│   ├── scan/
│   │   ├── data/         # ScanRepository (OCR → NER → Firestore)
│   │   └── presentation/
│   │       ├── providers/ # ScanNotifier (StateNotifier)
│   │       └── screens/   # HomeScreen, ScanScreen, ResultScreen
│   │
│   └── history/
│       ├── data/         # HistoryRepository (Firestore reads)
│       └── presentation/
│           └── screens/   # HistoryScreen
│
├── models/               # ScanResultModel, AllergenModel, AdditiveModel, UserModel
├── widgets/              # Reusable: AppButton, AppTextField, AllergenCard, etc.
├── l10n/                 # EN/FR localization ARB files
├── main.dart
└── firebase_options.dart
```

### Key patterns used:
- **Clean Architecture**: Data → Domain → Presentation
- **Riverpod**: StateNotifier + Provider + StreamProvider + FutureProvider
- **Either<Failure, T>**: Typed error handling (dartz)
- **Repository Pattern**: All data access abstracted behind repositories

---

## ⚙️ Setup Instructions

### 1. Prerequisites

```bash
flutter --version   # Requires Flutter 3.16+
dart --version      # Requires Dart 3.0+
```

Install Flutter: https://flutter.dev/docs/get-started/install

### 2. Clone / Extract the project

```bash
cd nutriscan_ner
flutter pub get
```

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: `nutriscan-ner`
3. Enable **Authentication** → Email/Password
4. Enable **Firestore Database** → Start in production mode
5. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
6. Configure Firebase:
   ```bash
   flutterfire configure
   ```
   This auto-generates `lib/firebase_options.dart` — replace the placeholder file.

7. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4. AI API Key (Mistral — recommended)

1. Sign up at https://console.mistral.ai
2. Get your API key
3. Set via `--dart-define`:
   ```bash
   flutter run --dart-define=MISTRAL_API_KEY=your_key_here
   ```
   
   Or create a `.env` approach (optional) and update `NerApiConfig.mistral`.

   **Alternative: OpenAI**
   ```bash
   flutter run --dart-define=OPENAI_API_KEY=your_key_here
   ```
   Then change `nerApiServiceProvider` to use `NerApiConfig.openai`.

> **Note:** If no API key is set, the app falls back to **local keyword-based detection** automatically. This works offline but is less accurate.

### 5. Android Permissions

Ensure `android/app/src/main/AndroidManifest.xml` has:
- `CAMERA`
- `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`
- `INTERNET`

The provided `android/AndroidManifest.xml` already includes these.

Also add to `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 6. iOS Permissions

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>NutriScan needs camera access to scan ingredient labels.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>NutriScan needs photo library access to import ingredient photos.</string>
```

### 7. Run the App

```bash
# Development
flutter run

# With API key
flutter run --dart-define=MISTRAL_API_KEY=your_key

# Release build
flutter build apk --release --dart-define=MISTRAL_API_KEY=your_key
```

---

## 🤖 AI API Details

### NER Request Example

```json
POST https://api.mistral.ai/v1/chat/completions
Authorization: Bearer {API_KEY}
Content-Type: application/json

{
  "model": "mistral-small-latest",
  "messages": [
    {
      "role": "system",
      "content": "You are a food safety expert..."
    },
    {
      "role": "user",
      "content": "Analyze this ingredient list:\nFarine de blé, lait entier, oeufs, E102, E211, sel, sucre"
    }
  ],
  "temperature": 0.1,
  "response_format": {"type": "json_object"}
}
```

### NER Response Example

```json
{
  "allergens": [
    {"name": "gluten/wheat", "severity": "high", "raw_text": "Farine de blé"},
    {"name": "milk",         "severity": "high", "raw_text": "lait entier"},
    {"name": "egg",          "severity": "medium","raw_text": "oeufs"}
  ],
  "additives": [
    {"code": "E102", "name": "Tartrazine",       "concern": "Hyperactivity in children", "raw_text": "E102"},
    {"code": "E211", "name": "Sodium Benzoate",  "concern": "Possible carcinogen with Vit C", "raw_text": "E211"}
  ],
  "confidence": 0.95
}
```

---

## 🔥 Firestore Schema

```
users/{userId}
  ├── uid: string
  ├── email: string
  ├── display_name: string?
  ├── created_at: string (ISO 8601)
  └── total_scans: number

  scan_history/{scanId}
    ├── user_id: string
    ├── extracted_text: string
    ├── allergens: AllergenModel[]
    ├── additives: AdditiveModel[]
    ├── confidence: number
    ├── timestamp: Timestamp
    └── image_url: string?
```

---

## 📊 Features

| Feature | Status |
|---------|--------|
| Email/Password Auth | ✅ |
| OCR (Google ML Kit) | ✅ |
| NER via Mistral AI | ✅ |
| Local fallback NER | ✅ |
| Firebase Firestore | ✅ |
| Offline handling | ✅ |
| Scan history | ✅ |
| History filtering | ✅ |
| Stats dashboard | ✅ |
| Bar chart (fl_chart) | ✅ |
| EN/FR localization | ✅ |
| Dark mode support | ✅ |
| Animations (flutter_animate) | ✅ |
| Error handling | ✅ |
| Clean architecture | ✅ |
| Riverpod state mgmt | ✅ |

---

## 🧩 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `firebase_core/auth/firestore` | Backend |
| `google_mlkit_text_recognition` | OCR |
| `dio` | HTTP client for NER API |
| `camera` / `image_picker` | Image capture |
| `fl_chart` | Data visualization |
| `flutter_animate` | Animations |
| `hive_flutter` | Local cache |
| `connectivity_plus` | Network detection |
| `dartz` | Functional error handling |
| `permission_handler` | Runtime permissions |

---

## 🛡️ Error Handling

Every error maps to a typed `Failure`:

| Failure | Cause |
|---------|-------|
| `NetworkFailure` | No internet |
| `TimeoutFailure` | API timeout |
| `OcrFailure` | OCR processing error |
| `NerFailure` | AI API error |
| `EmptyScanFailure` | No text found in image |
| `AuthFailure` | Firebase Auth error |
| `CameraFailure` | Camera permission denied |
| `CacheFailure` | Hive storage error |

The app **never crashes** — all errors show user-friendly SnackBars and the NER service has a local keyword fallback.

---

## 📁 Assets

Create these directories and add placeholder assets:
```
assets/
├── images/        # App images
├── icons/         # Custom icons
└── animations/    # Lottie JSON files (optional)
```

For fonts, download **Nunito Sans** from Google Fonts and place in `assets/fonts/`.

---

## 👨‍💻 Author Notes

- `lib/core/services/ner_api_service.dart` — core AI integration
- `lib/features/scan/data/scan_repository.dart` — full scan pipeline
- `lib/core/constants/app_constants.dart` — `nerSystemPrompt` can be tuned
- Switch between Mistral/OpenAI by changing `nerApiServiceProvider` config

---

*NutriScan NER — Built with Flutter, Firebase, and Mistral AI*
