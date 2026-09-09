import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../db/database_helper.dart';
import '../difficulty/difficulty_engine.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../sync/sync_service.dart';

class PatternVoiceScreen extends StatefulWidget {
  const PatternVoiceScreen({super.key});

  @override
  State<PatternVoiceScreen> createState() => _PatternVoiceScreenState();
}

class _PatternVoiceScreenState extends State<PatternVoiceScreen> {
  // Keys, not literal English text — the button label AND the word speech
  // recognition compares against both come from AppStrings.t(key), so they
  // always match whatever language is currently selected.
  static const _prompts = [
    {'key': 'object_flower', 'icon': Icons.local_florist},
    {'key': 'object_umbrella', 'icon': Icons.umbrella},
    {'key': 'object_bird', 'icon': Icons.flutter_dash},
  ];

  // Best-effort locale codes for the phone's own TTS/speech-recognition
  // engines. Whether Assamese actually works depends entirely on what's
  // installed on that specific device — most Android phones don't ship
  // Assamese TTS/STT voices at all. This is why the PRD calls for a
  // dedicated service (Bhashini/AI4Bharat) longer-term; until that's
  // wired in, this just tries the device's own engine and silently keeps
  // working in whatever language it actually supports if Assamese isn't
  // available.
  static const _ttsLocales = {'en': 'en-US', 'as': 'as-IN'};
  static const _speechLocales = {'en': 'en_US', 'as': 'as_IN'};

  static const String _gameType = 'pattern_voice';

  final _tts = FlutterTts();
  final _speech = stt.SpeechToText();

  late List<Map<String, dynamic>> _roundOrder;
  int _roundIndex = 0;
  bool _speechAvailable = false;
  bool _isListening = false;
  String? _feedback; // 'correct', 'wrong', or null while awaiting an answer
  int _correctCount = 0;
  int _totalAttempts = 0;
  int? _patientId;
  // Same reasoning as Memory Match: play immediately at the default tier
  // rather than waiting on a database lookup, and only redeal if the real
  // tier (loaded quietly in the background) turns out to be different.
  int _currentTier = DifficultyEngine.minTier;
  // Timed per round (reset when each new prompt appears), not across the
  // whole multi-round session — a session-wide average would include every
  // TTS narration and transition delay along the way, which has nothing to
  // do with how quickly the patient actually answered once asked.
  DateTime? _roundStartedAt;
  double _totalResponseSeconds = 0;

  Map<String, dynamic> get _currentPrompt => _roundOrder[_roundIndex];

  @override
  void initState() {
    super.initState();
    _roundOrder = _buildRoundOrder();
    _roundStartedAt = DateTime.now();
    _initSpeech();
    _setVoiceLocale();
    _tts.speak(AppStrings.t('question_spoken'));
    _loadRealTier();
  }

  Future<void> _setVoiceLocale() async {
    final ttsLocale = _ttsLocales[LocaleController.instance.languageCode];
    if (ttsLocale == null) return;
    try {
      await _tts.setLanguage(ttsLocale);
    } catch (_) {
      // Not supported on this device's TTS engine — keep whatever
      // language it defaults to rather than failing the game over it.
    }
  }

  // More rounds at higher tiers — same tier+2 formula as Memory Match, so
  // it's the same number to explain either way. With only 3 real prompts to
  // draw from, higher tiers repeat them rather than needing new content.
  List<Map<String, dynamic>> _buildRoundOrder() {
    final roundCount = (_currentTier + 2).clamp(3, 7);
    final order = <Map<String, dynamic>>[];
    while (order.length < roundCount) {
      order.addAll(_prompts);
    }
    final rounds = order.sublist(0, roundCount);
    rounds.shuffle();
    return rounds;
  }

  Future<void> _loadRealTier() async {
    try {
      final patientId =
          _patientId ?? await DatabaseHelper.instance.getOrCreateDefaultPatient();
      final tier = await DifficultyEngine.tierForPatient(
        patientId: patientId,
        gameType: _gameType,
      );
      if (!mounted) return;
      _patientId = patientId;
      if (tier != _currentTier) {
        setState(() {
          _currentTier = tier;
          _roundOrder = _buildRoundOrder();
          _roundIndex = 0;
          _correctCount = 0;
          _totalAttempts = 0;
          _totalResponseSeconds = 0;
          _feedback = null;
          _roundStartedAt = DateTime.now();
        });
        _tts.speak(AppStrings.t('question_spoken'));
      }
    } catch (_) {
      // No patient/tier history available — keep playing at the default.
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || _feedback != null) return;
    setState(() {
      _isListening = true;
      _feedback = null;
    });
    final localeId = _speechLocales[LocaleController.instance.languageCode];
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: localeId),
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _isListening = false);
          final expectedWord = AppStrings.t(_currentPrompt['key'] as String);
          _handleAnswer(
            result.recognizedWords.toLowerCase().contains(
                  expectedWord.toLowerCase(),
                ),
          );
        }
      },
    );
  }

  Future<void> _handleAnswer(bool isCorrect) async {
    if (_feedback != null) return; // one answer per round

    _speech.stop();
    _totalAttempts++;
    if (isCorrect) _correctCount++;
    _totalResponseSeconds +=
        DateTime.now().difference(_roundStartedAt!).inMilliseconds / 1000;

    setState(() {
      _isListening = false;
      _feedback = isCorrect ? 'correct' : 'wrong';
    });
    await _tts.speak(
      isCorrect
          ? AppStrings.t('correct_feedback')
          : AppStrings.t('feedback_wrong_spoken'),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (_roundIndex < _roundOrder.length - 1) {
      setState(() {
        _roundIndex++;
        _feedback = null;
        _roundStartedAt = DateTime.now();
      });
      _tts.speak('What is this?');
    } else {
      await _saveSession();
      _showCompleteDialog();
    }
  }

  Future<void> _saveSession() async {
    if (_patientId == null) return;

    await DatabaseHelper.instance.insertGameSession({
      'patient_id': _patientId,
      'game_type': _gameType,
      'difficulty_tier': _currentTier,
      'accuracy': _correctCount / _totalAttempts,
      'response_time_seconds': _totalResponseSeconds / _totalAttempts,
      'correct_answers': _correctCount,
      'total_answers': _totalAttempts,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Fire-and-forget: don't make the patient wait on a network round trip
    // just to see the "well done" dialog. If it fails (no internet), the
    // row stays marked unsynced and goes out with the next attempt.
    unawaited(SyncService.instance.syncAll());
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('well_done_title')),
        content: Text(
          AppStrings.t('correct_of_total_message', {
            'correct': '$_correctCount',
            'total': '$_totalAttempts',
          }),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _roundOrder = _buildRoundOrder();
                _roundIndex = 0;
                _correctCount = 0;
                _totalAttempts = 0;
                _totalResponseSeconds = 0;
                _feedback = null;
                _roundStartedAt = DateTime.now();
              });
              _tts.speak(AppStrings.t('question_spoken'));
              // This round's result may have just shifted the tier — check
              // again for next round, same as on first load.
              _loadRealTier();
            },
            child: Text(
              AppStrings.t('play_again_button'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _currentPrompt;
    final canAnswer = _feedback == null;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('pattern_voice_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${AppStrings.t('round_progress', {
                    'n': '${_roundIndex + 1}',
                    'total': '${_roundOrder.length}',
                  })}  •  ${AppStrings.t('level_label', {
                    'tier': '$_currentTier',
                  })}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Icon(prompt['icon'] as IconData, size: 100, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              AppStrings.t('question_spoken'),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _prompts.map((choice) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 56),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: canAnswer
                      ? () => _handleAnswer(choice['key'] == prompt['key'])
                      : null,
                  child: Text(AppStrings.t(choice['key'] as String)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.t('voice_hint'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            IconButton(
              iconSize: 64,
              color: _isListening ? Colors.red : Colors.indigo,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              onPressed: canAnswer && _speechAvailable
                  ? _startListening
                  : null,
            ),
            if (!_speechAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.t('no_voice_available'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _feedback == 'correct'
                      ? AppStrings.t('correct_feedback')
                      : AppStrings.t('feedback_wrong_next'),
                  style: TextStyle(
                    fontSize: 20,
                    color: _feedback == 'correct' ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
