import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../difficulty/difficulty_engine.dart';
import '../l10n/app_strings.dart';
import '../sync/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_header.dart';
import '../widgets/result_dialog.dart';

class AttentionSweepScreen extends StatefulWidget {
  const AttentionSweepScreen({super.key});

  @override
  State<AttentionSweepScreen> createState() => _AttentionSweepScreenState();
}

class _AttentionSweepScreenState extends State<AttentionSweepScreen> {
  static const String _gameType = 'attention_sweep';
  static const int _totalRounds = 5;

  // (common, odd) real-photo pairs to spot the different one among — the
  // same "find the one that doesn't belong" visual-search task, but with
  // recognizable real photos instead of abstract shapes. A new pair is
  // picked each round purely for variety; it has no effect on difficulty,
  // which still comes entirely from _cellCountForTier/_timeLimitForTier
  // below.
  static const List<List<String>> _objectPairs = [
    ['assets/images/elephant.jpg', 'assets/images/rhino.jpg'],
    ['assets/images/butterfly.jpg', 'assets/images/hornbill.jpg'],
    ['assets/images/gibbon.jpg', 'assets/images/cow.jpg'],
    ['assets/images/tea.jpg', 'assets/images/rice.jpg'],
  ];

  int? _patientId;
  int _currentTier = DifficultyEngine.minTier;

  int _roundIndex = 0;
  int _correctCount = 0;
  int _totalAttempts = 0;
  int _cellCount = 4;
  int _oddCellIndex = 0;
  List<String> _currentPair = _objectPairs.first;
  // A shuffled queue of pairs, consumed one per round — every pair shows
  // once before any of them repeat, rather than each round picking
  // independently at random (which could show the same pair back-to-back).
  final List<List<String>> _pairQueue = [];
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

  // Refills the queue with a freshly shuffled pass through every pair once
  // it runs out, fixing up the boundary so the last pair of the old
  // shuffle can't immediately repeat as the first pair of the new one.
  List<String> _nextPair() {
    if (_pairQueue.isEmpty) {
      _pairQueue.addAll(_objectPairs);
      _pairQueue.shuffle(_random);
      if (_pairQueue.length > 1 && _pairQueue.first == _currentPair) {
        final repeated = _pairQueue.removeAt(0);
        _pairQueue.insert(1, repeated);
      }
    }
    return _pairQueue.removeAt(0);
  }

  void _dealRound() {
    _countdownTimer?.cancel();
    _cellCount = _cellCountForTier(_currentTier);
    _oddCellIndex = _random.nextInt(_cellCount);
    _currentPair = _nextPair();
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
    showResultDialog(
      context,
      title: AppStrings.t('well_done_title'),
      message: AppStrings.t('correct_of_total_message', {
        'correct': '$_correctCount',
        'total': '$_totalAttempts',
      }),
      actionLabel: AppStrings.t('play_again_button'),
      accent: AppColors.sageDark,
      onAction: () {
        setState(() {
          _roundIndex = 0;
          _correctCount = 0;
          _totalAttempts = 0;
          _sessionStartedAt = DateTime.now();
          _dealRound();
        });
        _loadRealTier();
      },
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
            GameHeader(
              accent: AppColors.sageDark,
              progressText: '${AppStrings.t('round_progress', {
                    'n': '${_roundIndex + 1}',
                    'total': '$_totalRounds',
                  })}  •  ${AppStrings.t('level_label', {
                    'tier': '$_currentTier',
                  })}',
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t('time_left_label', {'seconds': '$_timeLeft'}),
              style: AppTextStyles.bodyLarge.copyWith(
                color: _timeLeft <= 2 ? AppColors.error : AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('attention_sweep_instruction'),
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sage, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          isOdd ? _currentPair[1] : _currentPair[0],
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                        ),
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
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _feedback == 'correct'
                        ? AppColors.sageDark
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
