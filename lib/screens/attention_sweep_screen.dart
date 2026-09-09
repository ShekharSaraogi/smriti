import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../difficulty/difficulty_engine.dart';
import '../l10n/app_strings.dart';
import '../sync/sync_service.dart';

class AttentionSweepScreen extends StatefulWidget {
  const AttentionSweepScreen({super.key});

  @override
  State<AttentionSweepScreen> createState() => _AttentionSweepScreenState();
}

class _AttentionSweepScreenState extends State<AttentionSweepScreen> {
  static const String _gameType = 'attention_sweep';
  static const IconData _commonIcon = Icons.circle;
  static const IconData _oddIcon = Icons.star;
  static const int _totalRounds = 5;

  int? _patientId;
  int _currentTier = DifficultyEngine.minTier;

  int _roundIndex = 0;
  int _correctCount = 0;
  int _totalAttempts = 0;
  int _cellCount = 4;
  int _oddCellIndex = 0;
  int _timeLeft = 8;
  Timer? _countdownTimer;
  String? _feedback; // 'correct', 'wrong', or null while awaiting a tap
  DateTime? _sessionStartedAt;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _dealRound();
    _loadRealTier();
  }

  int _cellCountForTier(int tier) => 4 + (tier - 1) * 2;
  int _timeLimitForTier(int tier) => (9 - tier).clamp(4, 8);

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
          _dealRound();
        });
      }
    } catch (_) {
      // No patient/tier history available — keep playing at the default.
    }
  }

  void _dealRound() {
    _countdownTimer?.cancel();
    _cellCount = _cellCountForTier(_currentTier);
    _oddCellIndex = _random.nextInt(_cellCount);
    _timeLeft = _timeLimitForTier(_currentTier);
    _feedback = null;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _handleAnswer(isCorrect: false, timedOut: true);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _handleAnswer({required bool isCorrect, bool timedOut = false}) {
    if (_feedback != null) return; // one answer per round
    _countdownTimer?.cancel();

    _totalAttempts++;
    if (isCorrect) _correctCount++;

    setState(() {
      _feedback = timedOut ? 'timeout' : (isCorrect ? 'correct' : 'wrong');
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_roundIndex < _totalRounds - 1) {
        setState(() {
          _roundIndex++;
          _dealRound();
        });
      } else {
        _saveSession();
        _showCompleteDialog();
      }
    });
  }

  Future<void> _saveSession() async {
    if (_patientId == null) return;
    final elapsedSeconds =
        DateTime.now().difference(_sessionStartedAt!).inMilliseconds / 1000;

    await DatabaseHelper.instance.insertGameSession({
      'patient_id': _patientId,
      'game_type': _gameType,
      'difficulty_tier': _currentTier,
      'accuracy': _correctCount / _totalAttempts,
      'response_time_seconds': elapsedSeconds / _totalAttempts,
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
                _roundIndex = 0;
                _correctCount = 0;
                _totalAttempts = 0;
                _sessionStartedAt = DateTime.now();
                _dealRound();
              });
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
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAnswer = _feedback == null;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('attention_sweep_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${AppStrings.t('round_progress', {
                    'n': '${_roundIndex + 1}',
                    'total': '$_totalRounds',
                  })}  •  ${AppStrings.t('level_label', {
                    'tier': '$_currentTier',
                  })}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t('time_left_label', {'seconds': '$_timeLeft'}),
              style: TextStyle(
                fontSize: 20,
                color: _timeLeft <= 2 ? Colors.red : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('attention_sweep_instruction'),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _cellCount,
                itemBuilder: (context, index) {
                  final isOdd = index == _oddCellIndex;
                  return GestureDetector(
                    key: ValueKey('cell_$index'),
                    onTap: canAnswer
                        ? () => _handleAnswer(isCorrect: isOdd)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Icon(
                        isOdd ? _oddIcon : _commonIcon,
                        size: 40,
                        color: Colors.indigo,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _feedback == 'correct'
                      ? AppStrings.t('correct_feedback')
                      : _feedback == 'timeout'
                          ? AppStrings.t('feedback_timeout')
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
