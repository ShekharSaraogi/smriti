import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/l10n/app_strings.dart';

void main() {
  test('returns the English text for a known key', () {
    expect(AppStrings.translate('home_games_button', 'en'), 'Games');
  });

  test('returns the Assamese text for a known key', () {
    expect(AppStrings.translate('home_games_button', 'as'), 'গেম');
  });

  test('falls back to English for a language with no entry at all', () {
    // Every real key is now fully translated into English and Assamese,
    // so this exercises the same fallback with a language that will never
    // have an entry ('fr'), rather than depending on some specific key
    // staying untranslated.
    expect(AppStrings.translate('home_games_button', 'fr'), 'Games');
  });

  test('falls back to the raw key when it does not exist at all', () {
    expect(AppStrings.translate('totally_made_up_key', 'en'), 'totally_made_up_key');
  });

  test('substitutes placeholders into the selected language template', () {
    final result = AppStrings.translate(
      'level_label',
      'as',
      {'tier': '3'},
    );
    expect(result, 'স্তৰ 3');
  });

  test('substitutes multiple placeholders', () {
    final result = AppStrings.translate(
      'correct_of_total_message',
      'en',
      {'correct': '4', 'total': '5'},
    );
    expect(result, 'You got 4 of 5 correct.');
  });
}
