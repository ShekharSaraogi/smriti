import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/l10n/app_strings.dart';

void main() {
  test('returns the English text for a known key', () {
    expect(AppStrings.translate('home_games_button', 'en'), 'Games');
  });

  test('returns the Assamese text for a known key', () {
    expect(AppStrings.translate('home_games_button', 'as'), 'গেম');
  });

  test('falls back to English when a key has no Assamese translation yet',
      () {
    // 'games_attention_sweep_button' was added after the translations
    // sheet was filled in and has no 'as' entry.
    expect(
      AppStrings.translate('games_attention_sweep_button', 'as'),
      'Attention Sweep',
    );
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
