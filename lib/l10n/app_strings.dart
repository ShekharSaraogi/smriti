import 'locale_controller.dart';

// Every user-facing piece of text in the app, keyed by a short identifier
// and keyed a second time by language code. Deliberately a plain map
// rather than Flutter's official .arb/gen-l10n system: with only two
// languages and no plurals/grammar rules to worry about, a map is far
// simpler to read, edit, and hand off pieces of to a non-coder teammate
// than generated code + a separate file format would be.
//
// Missing translations fall back to English, then to the raw key itself,
// so a string nobody has translated yet never crashes the app — it just
// shows in English until someone fills it in.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'app_name': {'en': 'Smriti', 'as': 'স্মৃতি'},

    'home_title': {'en': 'Smriti', 'as': 'স্মৃতি'},
    'home_games_button': {'en': 'Games', 'as': 'গেম'},
    'home_reminders_button': {'en': 'Reminders', 'as': 'সোঁৱৰণী'},
    'home_settings_button': {'en': 'Settings', 'as': 'ছেটিংছ'},

    'games_title': {'en': 'Games', 'as': 'গেম'},
    'games_memory_match_button': {'en': 'Memory Match', 'as': 'স্মৃতি মিলোৱা'},
    'games_pattern_voice_button': {
      'en': 'Pattern & Voice',
      'as': 'পেটাৰ্ণ আৰু মাত',
    },
    // Added after the translations sheet was filled in — not translated yet.
    'games_attention_sweep_button': {'en': 'Attention Sweep'},
    'games_routine_recall_button': {'en': 'Routine Recall'},

    // Shared across every game's progress line ("Round 2 of 5  •  Level 3").
    'level_label': {'en': 'Level {tier}', 'as': 'স্তৰ {tier}'},
    'well_done_title': {'en': 'Well done!', 'as': 'বহুত ভাল!'},
    'play_again_button': {'en': 'Play again', 'as': 'আকৌ খেলক'},
    'correct_feedback': {'en': 'Correct!', 'as': 'শুদ্ধ!'},
    'correct_of_total_message': {
      'en': 'You got {correct} of {total} correct.',
      'as': 'আপুনি {total} ৰ ভিতৰত {correct} টা শুদ্ধ কৰিছে।',
    },

    'memory_match_title': {'en': 'Memory Match', 'as': 'স্মৃতি মিলোৱা'},
    'memory_match_progress': {
      'en': 'Pairs found: {count} of {total}',
      'as': '{total} ৰ ভিতৰত {count} যোৰা পোৱা গৈছে।',
    },
    'memory_match_win_message': {
      'en': 'You found all {pairs} pairs.\n'
          'Attempts: {attempts}\n'
          'Accuracy: {percent}%',
      'as': 'আপুনি আটাইকেইটা {pairs} যোৰা বিচাৰি পালে। '
          'চেষ্টা: {attempts} শুদ্ধতা: {percent}%',
    },

    'pattern_voice_title': {'en': 'Pattern & Voice', 'as': 'পেটাৰ্ণ আৰু মাত'},
    'object_flower': {'en': 'Flower', 'as': 'ফুল'},
    'object_umbrella': {'en': 'Umbrella', 'as': 'ছাতি'},
    'object_bird': {'en': 'Bird', 'as': 'চৰাই'},
    'question_spoken': {'en': 'What is this?', 'as': 'এইটো কি?'},
    'round_progress': {
      'en': 'Round {n} of {total}',
      'as': '{total} ৰ ভিতৰত ৰাউণ্ড {n}',
    },
    'voice_hint': {'en': 'or answer by voice:', 'as': 'বা মাতেৰে উত্তৰ দিয়ক:'},
    'feedback_wrong_spoken': {'en': 'Not quite.', 'as': 'সঠিক নহয়।'},
    'feedback_wrong_next': {
      'en': 'Not quite — next one',
      'as': 'সঠিক নহয় - পৰৱৰ্তীটো',
    },
    'no_voice_available': {
      'en': 'Voice input unavailable on this device — use the buttons above.',
      'as': 'এই ডিভাইচটোত ভইচ ইনপুট উপলব্ধ নহয় - ওপৰৰ বুটামবোৰ ব্যৱহাৰ কৰক।',
    },

    // Added after the translations sheet was filled in — not translated yet.
    'attention_sweep_title': {'en': 'Attention Sweep'},
    'attention_sweep_instruction': {'en': 'Tap the different one'},
    'time_left_label': {'en': 'Time left: {seconds} s'},
    'feedback_timeout': {'en': "Time's up — next one"},

    'routine_recall_title': {'en': 'Routine Recall'},
    'routine_recall_prompt': {'en': 'After "{step}", what comes next?'},
    'routine_recall_not_set_up': {
      'en': 'No daily routine has been set up yet. Ask a caregiver to add '
          'one before playing this game.',
    },
    'set_up_routine_button': {'en': 'Set up routine'},

    'routine_entry_title': {'en': 'Daily Routine'},
    'routine_entry_helper': {
      'en': 'Enter the steps of a typical day, in order (e.g. Wake up, '
          'Breakfast, Take medicine...). Routine Recall quizzes on this '
          'same order.',
    },
    'add_step_button': {'en': 'Add step'},
    'save_button': {'en': 'Save'},
    'routine_min_steps_error': {'en': 'Please enter at least {min} steps.'},
    'routine_saved_snackbar': {'en': 'Daily routine saved'},

    'reminders_title': {'en': 'Reminders', 'as': 'সোঁৱৰণী'},
    'set_reminder_button': {
      'en': 'Set medicine reminder',
      'as': 'ঔষধৰ সোঁৱৰণী ছেট কৰক',
    },
    'no_reminders_yet': {'en': 'No reminders yet', 'as': 'এতিয়ালৈকে কোনো সোঁৱৰণী নাই'},
    'reminder_set_snackbar': {
      'en': 'Medicine reminder set for {time}',
      'as': '{time} ৰ বাবে ঔষধৰ সোঁৱৰণী ছেট কৰা হৈছে',
    },
    'reminder_notification_body': {
      'en': 'Time to take your medicine',
      'as': 'আপোনাৰ ঔষধ খোৱাৰ সময় হৈছে',
    },
    // Not in the translations sheet (it lists internal status codes, not
    // this display label) — not translated yet.
    'reminder_upcoming_status': {'en': 'Upcoming'},
    'reminder_missed_status': {'en': 'Missed'},

    'settings_title': {'en': 'Settings', 'as': 'ছেটিংছ'},
    // Replaces the sheet's "Settings coming soon" placeholder, which no
    // longer exists in the app — not translated yet.
    'edit_daily_routine_button': {'en': 'Edit Daily Routine'},
    'language_label': {'en': 'Language'},
  };

  // The pure lookup — takes the language explicitly, so it's trivial to
  // unit test without touching LocaleController or any app state.
  static String translate(
    String key,
    String languageCode, [
    Map<String, String>? params,
  ]) {
    var template =
        _strings[key]?[languageCode] ?? _strings[key]?['en'] ?? key;
    params?.forEach((name, value) {
      template = template.replaceAll('{$name}', value);
    });
    return template;
  }

  // What screens actually call: reads whichever language is currently
  // selected, so callers never have to thread it through themselves.
  static String t(String key, [Map<String, String>? params]) {
    return translate(key, LocaleController.instance.languageCode, params);
  }
}
