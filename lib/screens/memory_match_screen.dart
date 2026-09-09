import 'dart:async';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../difficulty/difficulty_engine.dart';
import '../l10n/app_strings.dart';
import '../sync/sync_service.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  // 7 is enough for the hardest tier (5 + 2 pairs). Adding a tier later
  // only means adding icons here, nothing else changes.
  static const List<IconData> _symbols = [
    Icons.local_florist,
    Icons.pets,
    Icons.umbrella,
    Icons.wb_sunny,
    Icons.star,
    Icons.cake,
    Icons.anchor,
  ];

  static const String _gameType = 'memory_match';

  // How long a wrong pair stays visible before flipping back. Deliberately
  // slow: the target user reads and reacts slowly on a bad day.
  static const Duration _mismatchPause = Duration(milliseconds: 1200);

  late List<IconData> _cards;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;

  int? _firstFlippedIndex;
  bool _isChecking = false;
  int _totalAttempts = 0;
  int _correctAttempts = 0;

  int? _patientId;
  // A brand new patient is tier 1 anyway, so dealing the board at that
  // default immediately — rather than waiting on a database lookup first —
  // means the game is instantly playable, with no loading screen in front
  // of it. The real tier loads quietly in the background afterward.
  int _currentTier = DifficultyEngine.minTier;
  DateTime? _roundStartedAt;

  int get _pairCount => _cards.length ~/ 2;

  @override
  void initState() {
    super.initState();
    _dealBoard();
    _loadRealTier();
  }

  // Looks up the patient's actual difficulty tier and, only if it turns out
  // to differ from the tier already showing, deals a fresh board for it.
  // Runs quietly in the background; if it fails (or never loads), the
  // patient can keep playing at the default tier regardless — a returning
  // player occasionally seeing the board redeal once their real tier loads
  // is a fine trade for never blocking a simple offline game on a database
  // round trip.
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
          _dealBoard();
        });
      }
    } catch (_) {
      // No patient/tier history available — the default tier already
      // showing is a perfectly reasonable one to keep playing at.
    }
  }

  void _dealBoard() {
    final pairCount = (_currentTier + 2).clamp(3, _symbols.length);
    final selected = _symbols.sublist(0, pairCount);

    _cards = [...selected, ...selected];
    _cards.shuffle();
    _isFlipped = List.filled(_cards.length, false);
    _isMatched = List.filled(_cards.length, false);
    _firstFlippedIndex = null;
    _isChecking = false;
    _totalAttempts = 0;
    _correctAttempts = 0;
    _roundStartedAt = DateTime.now();
  }

  Future<void> _saveCompletedRound() async {
    if (_patientId == null) return;

    final elapsedSeconds =
        DateTime.now().difference(_roundStartedAt!).inMilliseconds / 1000;

    await DatabaseHelper.instance.insertGameSession({
      'patient_id': _patientId,
      'game_type': _gameType,
      'difficulty_tier': _currentTier,
      'accuracy': _correctAttempts / _totalAttempts,
      'response_time_seconds': elapsedSeconds / _totalAttempts,
      'correct_answers': _correctAttempts,
      'total_answers': _totalAttempts,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Fire-and-forget: don't make the patient wait on a network round trip
    // just to see the "well done" dialog. If it fails (no internet), the
    // row stays marked unsynced and goes out with the next attempt.
    unawaited(SyncService.instance.syncAll());
  }

  void _onCardTapped(int index) {
    if (_isChecking) return;
    if (_isFlipped[index]) return;

    setState(() {
      _isFlipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
      return;
    }

    final firstIndex = _firstFlippedIndex!;
    _firstFlippedIndex = null;
    final isMatch = _cards[firstIndex] == _cards[index];

    setState(() {
      _totalAttempts++;
      if (isMatch) {
        _correctAttempts++;
        _isMatched[firstIndex] = true;
        _isMatched[index] = true;
      } else {
        _isChecking = true;
      }
    });

    if (isMatch) {
      if (_isMatched.every((matched) => matched)) {
        _saveCompletedRound();
        _showRoundCompleteDialog();
      }
      return;
    }

    Future.delayed(_mismatchPause, () {
      if (!mounted) return;
      setState(() {
        _isFlipped[firstIndex] = false;
        _isFlipped[index] = false;
        _isChecking = false;
      });
    });
  }

  Future<void> _showRoundCompleteDialog() async {
    // Let the final pair register before covering the board with a dialog.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final accuracy = (_correctAttempts / _totalAttempts * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('well_done_title')),
        content: Text(
          AppStrings.t('memory_match_win_message', {
            'pairs': '$_pairCount',
            'attempts': '$_totalAttempts',
            'percent': '$accuracy',
          }),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _dealBoard());
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('memory_match_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${AppStrings.t('memory_match_progress', {
                    'count': '$_correctAttempts',
                    'total': '$_pairCount',
                  })}  •  ${AppStrings.t('level_label', {
                    'tier': '$_currentTier',
                  })}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final isMatched = _isMatched[index];
                final isFaceUp = _isFlipped[index];

                return GestureDetector(
                  key: ValueKey('card_$index'),
                  onTap: () => _onCardTapped(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMatched
                          ? Colors.green.shade100
                          : isFaceUp
                              ? Colors.white
                              : Colors.indigo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMatched
                            ? Colors.green.shade400
                            : Colors.indigo.shade200,
                      ),
                    ),
                    child: Center(
                      child: isFaceUp
                          ? Icon(
                              _cards[index],
                              size: 40,
                              color: isMatched
                                  ? Colors.green.shade800
                                  : Colors.indigo,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
