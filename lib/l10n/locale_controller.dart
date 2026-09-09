import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds the currently selected UI language and persists it across app
// restarts. A ChangeNotifier rather than anything fancier — main.dart
// listens once at the app root and rebuilds everything below it whenever
// the language changes, which is all a 2-language switch needs.
class LocaleController extends ChangeNotifier {
  LocaleController._privateConstructor();
  static final LocaleController instance = LocaleController._privateConstructor();

  static const _prefsKey = 'language_code';

  // Language name is written in that language itself, not English, so a
  // patient who can't read English can still recognize their own language
  // in the picker.
  static const supportedLanguages = {'en': 'English', 'as': 'অসমীয়া'};

  String _languageCode = 'en';
  String get languageCode => _languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefsKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
