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
    'home_games_description': {
      'en': 'Play a memory or attention game',
      'as': 'স্মৃতি বা মনোযোগৰ গেম খেলক',
    },
    'home_reminders_description': {
      'en': 'Medicine, water, and appointments',
      'as': 'ঔষধ, পানী, আৰু সাক্ষাৎ',
    },
    'home_routine_button': {'en': 'Daily Routine', 'as': 'দৈনন্দিন কাৰ্যক্ৰম'},
    'home_routine_description': {
      'en': 'Set up your everyday steps',
      'as': 'আপোনাৰ দৈনন্দিন কামবোৰ ছেট কৰক',
    },
    'home_settings_description': {
      'en': 'Language and preferences',
      'as': 'ভাষা আৰু পছন্দ',
    },

    'games_title': {'en': 'Games', 'as': 'গেম'},
    'games_memory_match_button': {'en': 'Memory Match', 'as': 'স্মৃতি মিলোৱা'},
    'games_pattern_voice_button': {
      'en': 'Pattern & Voice',
      'as': 'পেটাৰ্ণ আৰু মাত',
    },
    'games_attention_sweep_button': {
      'en': 'Attention Sweep',
      'as': 'মনোযোগ পৰীক্ষা',
    },
    'games_routine_recall_button': {
      'en': 'Routine Recall',
      'as': 'কাৰ্যক্ৰম সোঁৱৰণ',
    },

    'games_memory_match_description': {
      'en': 'Find the matching pairs',
      'as': 'মিল থকা যোৰাবোৰ বিচাৰি উলিয়াওক',
    },
    'games_pattern_voice_description': {
      'en': 'Name what you see or hear',
      'as': 'আপুনি যি দেখে বা শুনে তাৰ নাম কওক',
    },
    'games_attention_sweep_description': {
      'en': 'Spot the one that is different',
      'as': 'পৃথকটো চিনাক্ত কৰক',
    },
    'games_routine_recall_description': {
      'en': 'Practice your daily steps',
      'as': 'আপোনাৰ দৈনন্দিন কামবোৰ অনুশীলন কৰক',
    },

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
    // Real-photo objects for Pattern & Voice.
    'object_cow': {'en': 'Cow', 'as': 'গাই'},
    'object_rooster': {'en': 'Rooster', 'as': 'কুকুৰা'},
    'object_fire': {'en': 'Fire', 'as': 'জুই'},
    'object_water': {'en': 'Water', 'as': 'পানী'},
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

    'attention_sweep_title': {
      'en': 'Attention Sweep',
      'as': 'মনোযোগ পৰীক্ষা',
    },
    'attention_sweep_instruction': {
      'en': 'Tap the different one',
      'as': 'পৃথকটোত টিপক',
    },
    'time_left_label': {
      'en': 'Time left: {seconds} s',
      'as': 'বাকী সময়: {seconds} ছেকেণ্ড',
    },
    'feedback_timeout': {
      'en': "Time's up — next one",
      'as': 'সময় শেষ - পৰৱৰ্তীটো',
    },

    'routine_recall_title': {
      'en': 'Routine Recall',
      'as': 'কাৰ্যক্ৰম সোঁৱৰণ',
    },
    'routine_recall_prompt': {
      'en': 'After "{step}", what comes next?',
      'as': '"{step}" ৰ পিছত, তাৰ পিছত কি আহে?',
    },
    'routine_recall_not_set_up': {
      'en': 'No daily routine has been set up yet. Ask a caregiver to add '
          'one before playing this game.',
      'as': 'এতিয়ালৈকে কোনো দৈনন্দিন কাৰ্যক্ৰম ছেট কৰা হোৱা নাই। এই গেমটো '
          'খেলাৰ আগতে যত্নকাৰীক এটা যোগ কৰিবলৈ কওক।',
    },
    'set_up_routine_button': {
      'en': 'Set up routine',
      'as': 'কাৰ্যক্ৰম ছেট কৰক',
    },

    'routine_entry_title': {'en': 'Daily Routine', 'as': 'দৈনন্দিন কাৰ্যক্ৰম'},
    'routine_entry_helper': {
      'en': 'Enter the steps of a typical day, in order (e.g. Wake up, '
          'Breakfast, Take medicine...). Routine Recall quizzes on this '
          'same order.',
      'as': 'এটা সাধাৰণ দিনৰ পদক্ষেপবোৰ ক্ৰমে লিখক (যেনে: শুই উঠা, প্ৰাতঃৰাশ, '
          'ঔষধ খোৱা...). কাৰ্যক্ৰম সোঁৱৰণে এই একে ক্ৰমৰ ওপৰত প্ৰশ্ন কৰে।',
    },
    'add_step_button': {'en': 'Add step', 'as': 'পদক্ষেপ যোগ কৰক'},
    'save_button': {'en': 'Save', 'as': 'সংৰক্ষণ কৰক'},
    'routine_min_steps_error': {
      'en': 'Please enter at least {min} steps.',
      'as': 'অনুগ্ৰহ কৰি কমেও {min} টা পদক্ষেপ দিয়ক।',
    },
    'routine_saved_snackbar': {
      'en': 'Daily routine saved',
      'as': "দৈনন্দিন কাৰ্যক্ৰম সংৰক্ষণ কৰা হ'ল",
    },

    'reminders_title': {'en': 'Reminders', 'as': 'সোঁৱৰণী'},
    'no_reminders_yet': {
      'en': 'No reminders yet',
      'as': 'এতিয়ালৈকে কোনো সোঁৱৰণী নাই',
    },
    'reminder_upcoming_status': {'en': 'Upcoming', 'as': 'আহি থকা'},
    'reminder_missed_status': {'en': 'Missed', 'as': 'বাদ পৰা'},
    'reminder_done_status': {'en': 'Done', 'as': 'সম্পন্ন'},
    'mark_done_button': {
      'en': 'Mark as done',
      'as': 'সম্পন্ন বুলি চিহ্নিত কৰক',
    },

    // One set of {type name, notification body, confirmation snackbar} per
    // reminder type — see reminders_screen.dart's _reminderTypes list.
    'reminder_type_medicine': {'en': 'Medicine', 'as': 'ঔষধ'},
    'reminder_type_hydration': {'en': 'Hydration', 'as': 'পানী পান'},
    'reminder_type_activity': {'en': 'Daily Activity', 'as': 'দৈনন্দিন কাম'},
    'reminder_type_appointment': {
      'en': 'Medical Appointment',
      'as': 'চিকিৎসা সাক্ষাৎ',
    },

    'reminder_notification_body_medicine': {
      'en': 'Time to take your medicine',
      'as': 'আপোনাৰ ঔষধ খোৱাৰ সময় হৈছে',
    },
    'reminder_notification_body_hydration': {
      'en': 'Time to drink some water',
      'as': 'পানী খোৱাৰ সময় হৈছে',
    },
    'reminder_notification_body_activity': {
      'en': 'Time for your daily activity',
      'as': 'আপোনাৰ দৈনন্দিন কামৰ সময় হৈছে',
    },
    'reminder_notification_body_appointment': {
      'en': 'Time for your medical appointment',
      'as': 'আপোনাৰ চিকিৎসা সাক্ষাতৰ সময় হৈছে',
    },

    'reminder_set_snackbar_medicine': {
      'en': 'Medicine reminder set for {time}',
      'as': '{time} ৰ বাবে ঔষধৰ সোঁৱৰণী ছেট কৰা হৈছে',
    },
    'reminder_set_snackbar_hydration': {
      'en': 'Hydration reminder set for {time}',
      'as': '{time} ৰ বাবে পানী খোৱাৰ সোঁৱৰণী ছেট কৰা হৈছে',
    },
    'reminder_set_snackbar_activity': {
      'en': 'Activity reminder set for {time}',
      'as': '{time} ৰ বাবে কামৰ সোঁৱৰণী ছেট কৰা হৈছে',
    },
    'reminder_set_snackbar_appointment': {
      'en': 'Appointment reminder set for {time}',
      'as': '{time} ৰ বাবে সাক্ষাতৰ সোঁৱৰণী ছেট কৰা হৈছে',
    },

    'edit_reminder_button': {'en': 'Edit', 'as': 'সম্পাদনা কৰক'},
    'delete_button': {'en': 'Delete', 'as': 'মচি পেলাওক'},
    'cancel_button': {'en': 'Cancel', 'as': 'বাতিল কৰক'},
    'delete_reminder_title': {
      'en': 'Delete reminder?',
      'as': 'সোঁৱৰণী মচি পেলাব নে?',
    },
    'delete_reminder_confirm': {
      'en': 'This cannot be undone.',
      'as': 'ই পূৰ্বাৱস্থালৈ অনা নাযাব।',
    },
    'reminder_time_in_past_error': {
      'en': 'Please pick a time in the future',
      'as': 'অনুগ্ৰহ কৰি ভৱিষ্যতৰ এটা সময় বাছক',
    },

    'settings_title': {'en': 'Settings', 'as': 'ছেটিংছ'},
    'edit_daily_routine_button': {
      'en': 'Edit Daily Routine',
      'as': 'দৈনন্দিন কাৰ্যক্ৰম সম্পাদনা কৰক',
    },
    'language_label': {'en': 'Language', 'as': 'ভাষা'},
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
