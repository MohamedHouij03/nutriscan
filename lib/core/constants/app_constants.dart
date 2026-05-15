// lib/core/constants/app_constants.dart

/// Global constants used across the application.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'NutriScan NER';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String scansCollection = 'scans';
  static const String historySubCollection = 'scan_history';

  // Hive boxes
  static const String scanHistoryBox = 'scan_history_box';
  static const String settingsBox = 'settings_box';
  static const String userBox = 'user_box';

  // SharedPreferences keys
  static const String prefLanguageCode = 'language_code';
  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboardingDone = 'onboarding_done';

  // API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration ocrTimeout = Duration(seconds: 15);

  // Pagination
  static const int historyPageSize = 20;

  // Image constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double imageQuality = 0.8;

  // NER prompt template
  static const String nerSystemPrompt = '''
You are a food safety expert specialized in detecting allergens and harmful additives in ingredient lists.

Analyze the provided ingredient list text and extract:
1. ALLERGENS: milk, egg, gluten/wheat, peanuts, tree nuts, soy, fish, shellfish, sesame, mustard, celery, lupin, molluscs, sulphites
2. HARMFUL ADDITIVES: E-numbers known to be controversial (e.g., E102, E110, E122, E124, E129, E210, E211, E220, E249, E250, E320, E321, E621)

Return ONLY valid JSON in this exact format:
{
  "allergens": [
    {"name": "milk", "severity": "high", "raw_text": "lait entier"}
  ],
  "additives": [
    {"code": "E102", "name": "Tartrazine", "concern": "hyperactivity in children", "raw_text": "E102"}
  ],
  "confidence": 0.95
}

If none found, return empty arrays. Never add explanations outside the JSON.
''';

  // Supported languages
  static const List<String> supportedLanguages = ['en', 'fr'];

  // Known allergen keywords (for local fallback)
  static const List<String> allergenKeywords = [
    'milk', 'lait', 'dairy', 'lactose',
    'egg', 'oeuf', 'eggs',
    'wheat', 'gluten', 'blé', 'farine',
    'peanut', 'arachide', 'peanuts',
    'nuts', 'noix', 'almond', 'amande',
    'soy', 'soja', 'soybean',
    'fish', 'poisson', 'cod', 'salmon',
    'shellfish', 'crustacé', 'shrimp', 'crevette',
    'sesame', 'sésame',
    'mustard', 'moutarde',
    'celery', 'céleri',
    'lupin', 'lupine',
    'sulphite', 'sulfite', 'E220', 'E221', 'E222',
  ];

  // Known harmful E-numbers
  static const List<String> harmfulENumbers = [
    'E102', 'E104', 'E107', 'E110', 'E120', 'E122', 'E123',
    'E124', 'E127', 'E128', 'E129', 'E131', 'E132', 'E133',
    'E142', 'E150d', 'E151', 'E154', 'E155', 'E173',
    'E210', 'E211', 'E212', 'E213', 'E214', 'E215',
    'E216', 'E217', 'E218', 'E219', 'E220', 'E221',
    'E249', 'E250', 'E251', 'E252',
    'E320', 'E321',
    'E407', 'E412',
    'E621', 'E622', 'E623', 'E624', 'E625',
  ];
}

/// Route names for GoRouter.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String history = '/history';
  static const String historyDetail = '/history/:id';
  static const String profile = '/profile';
}
