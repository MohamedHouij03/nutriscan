# Quick Fix Guide for Common Flutter ML Kit Errors

## Error: "No implementation found for method vision#startTextRecognizer"

### Quick Fix (Try These in Order)

1. **Clean and rebuild:**

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **If still failing, regenerate platforms:**

   ```bash
   flutter create --platforms=android,ios .
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Check Android build (if on Android):**

   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

4. **Check iOS pods (if on iOS):**
   ```bash
   cd ios
   rm -rf Pods
   pod install
   cd ..
   flutter run
   ```

---

## Error: "Cloud Firestore offline"

### Quick Fix

1. Check internet connectivity on device/emulator
2. Ensure Firebase is initialized before using Firestore:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
3. Add Firestore offline persistence (optional):
   ```dart
   FirebaseFirestore.instance.settings = const Settings(
     persistenceEnabled: true,
   );
   ```

---

## Error: "plugin java.io.FileNotFoundException"

### Quick Fix

```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

---

## Verification Checklist

- [ ] Run `flutter doctor -v` - all checks green
- [ ] `pubspec.yaml` has `google_mlkit_text_recognition: ^0.15.1`
- [ ] Android: `build.gradle.kts` exists and has no errors
- [ ] iOS: `Pods/` directory exists (run `pod install` if not)
- [ ] Device/emulator has internet connection
- [ ] App permissions for camera are granted at runtime

---

## Testing OCR Functionality

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<void> testOcr() async {
  final inputImage = InputImage.fromFilePath('path/to/image.jpg');
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final recognizedText = await textRecognizer.processImage(inputImage);
  print('Text: ${recognizedText.text}');
  await textRecognizer.close();
}
```

---

## Reset Complete Environment

If all else fails:

```bash
# Remove all cache
flutter clean
rm -rf pubspec.lock
rm -rf .flutter-plugins-dependencies
rm -rf android/.gradle
rm -rf ios/Pods

# Reinstall everything
flutter pub get
flutter create --platforms=android,ios .
flutter run
```

---

## Performance Tips

- Use `flutter build apk --release` for production
- First build takes 5-10 minutes (normal)
- ML Kit models download on first OCR call
- Subsequent runs are faster due to caching
