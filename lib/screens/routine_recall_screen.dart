import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../difficulty/difficulty_engine.dart';
import '../l10n/app_strings.dart';
import '../sync/sync_service.dart';
import 'routine_entry_screen.dart';

// Quizzes the patient on the order of their own daily routine: "after
// this step, what comes next?" with 3 tappable choices. Unlike the other
// 3 games, there's no sensible hardcoded content here — the whole point
// is that it's THIS patient's own routine — so, unavoidably, it does need
// to load that from the database before it can show anything meaningful
// (a brief spinner, not the instant-deal pattern the other games use).
class RoutineRecallScreen extends StatefulWidget {
  const RoutineRecallScreen({super.key});

  @override
  State<RoutineRecallScreen> createState() => _RoutineRecallScreenState();
}

class _RoutineRecallScreenState extends State<RoutineRecallScreen> {
  static const String _gameType = 'routine_recall';
  // Needs at least 4: each round excludes both the prompt step and the
  // correct answer from the distractor pool (see _buildChoicesForCurrentRound),
  // so 2 distinct distractors require at least 2 other steps to remain.
  static const int _minRoutineSteps = 4;

  int? _patientId;
  int _currentTier = DifficultyEngine.minTier;
  List<String> _routineSteps = [];
  bool _isLoadingRoutine = true;

  late List<int> _roundOrder; // prompt step indices into _routineSteps
  int _roundIndex = 0;
  late List<String> _currentChoices;
  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _feedback; // 'correct', 'wrong', or null while awaiting an answer
  DateTime? _roundStartedAt;
  double _totalResponseSeconds = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    final patientId =
        await DatabaseHelper.instance.getOrCreateDefaultPatient();
    final patients = await DatabaseHelper.instance.getPatients();
    final patient = patients.firstWhere((p) => p['id'] == patientId);
    final rawRoutine = patient['daily_routine'] as String?;

    var steps = <String>[];
    if (rawRoutine != null && rawRoutine.isNotEmpty) {
      try {
        steps = (jsonDecode(rawRoutine) as List).cast<String>();
      } catch (_) {
        steps = [];
      }
    }

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _routineSteps = steps;
      _isLoadingRoutine = false;
      if (_routineSteps.length >= _minRoutineSteps) {
        _dealRound();
      }
    });
    if (_routineSteps.length >= _minRoutineSteps) {
      _loadRealTier();
    }
  }

  Future<void> _loadRealTier() async {
    try {
      final tier = await DifficultyEngine.tierForPatient(
        patientId: _patientId!,
        gameType: _gameType,
      );
      if (!mounted) return;
      if (tier != _currentTier) {
        setState(() {
          _currentTier = tier;
          _dealRound();
        });
      }
    } catch (_) {
      // No tier history available — the default tier already showing is a
      // perfectly reasonable one to keep playing at.
    }
  }

  // Every step except the last one can be asked about ("what comes after
  // this?"); the last step has no "next" to quiz on.
  List<int> _eligiblePromptIndices() =>
      List.generate(_routineSteps.length - 1, (i) => i);

  void _dealRound() {
    final eligible = _eligiblePromptIndices();
    final roundCount = (_currentTier + 2).clamp(3, 7);
    final order = <int>[];
    while (order.length < roundCount) {
      order.addAll(eligible);
    }
    order.shuffle(_random);
    _roundOrder = order.sublist(0, roundCount);

    _roundIndex = 0;
    _correctCount = 0;
    _totalAttempts = 0;
    _totalResponseSeconds = 0;
    _feedback = null;
    _buildChoicesForCurrentRound();
    _roundStartedAt = DateTime.now();
  }

  void _buildChoicesForCurrentRound() {
    final promptIndex = _roundOrder[_roundIndex];
    final correctAnswer = _routineSteps[promptIndex + 1];

    // Excludes the prompt step itself, not just the correct answer —
    // otherwise "After Wake up, what comes next?" could offer "Wake up"
    // back as one of the choices, which makes no sense as an answer.
    final distractorPool = [
      for (var i = 0; i < _routineSteps.length; i++)
        if (i != promptIndex && i != promptIndex + 1) _routineSteps[i],
    ]..shuffle(_random);

    final choices = <String>{correctAnswer};
    for (final candidate in distractorPool) {
      if (choices.length >= 3) break;
      choices.add(candidate);
    }
    _currentChoices = choices.toList()..shuffle(_random);
  }

  String get _currentPromptStep => _routineSteps[_roundOrder[_roundIndex]];

  Future<void> _handleAnswer(String chosen) async {
    if (_feedback != null) return; // one answer per round

    final promptIndex = _roundOrder[_roundIndex];
    final isCorrect = chosen == _routineSteps[promptIndex + 1];

    _totalAttempts++;
    if (isCorrect) _correctCount++;
    _totalResponseSeconds +=
        DateTime.now().difference(_roundStartedAt!).inMilliseconds / 1000;

    setState(() {
      _feedback = isCorrect ? 'correct' : 'wrong';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (_roundIndex < _roundOrder.length - 1) {
      setState(() {
        _roundIndex++;
        _feedback = null;
        _buildChoicesForCurrentRound();
        _roundStartedAt = DateTime.now();
      });
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
              setState(_dealRound);
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

  Future<void> _goToRoutineEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoutineEntryScreen()),
    );
    if (!mounted) return;
    setState(() => _isLoadingRoutine = true);
    _loadRoutine();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRoutine) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('routine_recall_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_routineSteps.length < _minRoutineSteps) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('routine_recall_title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.t('routine_recall_not_set_up'),
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(240, 64),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: _goToRoutineEntry,
                  child: Text(AppStrings.t('set_up_routine_button')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canAnswer = _feedback == null;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('routine_recall_title'))),
      body: Padding(
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
            Text(
              // The routine step text itself is whatever the caregiver
              // typed in — not translated, since it's free-form user
              // content, not app UI text.
              AppStrings.t('routine_recall_prompt', {
                'step': _currentPromptStep,
              }),
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ..._currentChoices.map(
              (choice) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 64),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: canAnswer ? () => _handleAnswer(choice) : null,
                    child: Text(choice),
                  ),
                ),
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
