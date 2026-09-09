import 'dart:convert';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/app_strings.dart';
import '../utils/routine_visuals.dart';

// Where a caregiver types in the patient's typical daily routine, in
// order (e.g. Wake up, Breakfast, Take medicine, ...). Stored as a JSON
// list of strings in patients.daily_routine — Routine Recall then quizzes
// on that same order.
class RoutineEntryScreen extends StatefulWidget {
  const RoutineEntryScreen({super.key});

  @override
  State<RoutineEntryScreen> createState() => _RoutineEntryScreenState();
}

class _RoutineEntryScreenState extends State<RoutineEntryScreen> {
  // Kept in sync with RoutineRecallScreen._minRoutineSteps — the game
  // needs at least this many steps to always have 2 valid distractors.
  static const int _minSteps = 4;

  int? _patientId;
  final List<TextEditingController> _controllers = [];
  bool _isLoading = true;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadExistingRoutine();
  }

  Future<void> _loadExistingRoutine() async {
    final patientId =
        await DatabaseHelper.instance.getOrCreateDefaultPatient();
    final patients = await DatabaseHelper.instance.getPatients();
    final patient = patients.firstWhere((p) => p['id'] == patientId);
    final rawRoutine = patient['daily_routine'] as String?;

    final steps = <String>[];
    if (rawRoutine != null && rawRoutine.isNotEmpty) {
      try {
        steps.addAll((jsonDecode(rawRoutine) as List).cast<String>());
      } catch (_) {
        // Unreadable stored data — start from a blank form rather than crash.
      }
    }
    // Always leave at least a few blank rows ready for typing, whether
    // editing an existing routine or starting from nothing.
    while (steps.length < _minSteps + 1) {
      steps.add('');
    }

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _controllers.addAll(steps.map((s) => TextEditingController(text: s)));
      _isLoading = false;
    });
  }

  void _addStep() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeStep(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    final steps = _controllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (steps.length < _minSteps) {
      setState(() {
        _saveError = AppStrings.t('routine_min_steps_error', {
          'min': '$_minSteps',
        });
      });
      return;
    }

    await DatabaseHelper.instance.updatePatientRoutine(
      _patientId!,
      jsonEncode(steps),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t('routine_saved_snackbar'))),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('routine_entry_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('routine_entry_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.t('routine_entry_helper'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      // Live preview of the picture this step will show in
                      // Routine Recall — lets the caregiver see right away
                      // that "Take morning medicine" becomes a pill icon,
                      // and reword it if the picture doesn't feel right.
                      AnimatedBuilder(
                        animation: _controllers[index],
                        builder: (context, _) => Text(
                          routineStepEmoji(_controllers[index].text),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: ValueKey('routine_step_$index'),
                          controller: _controllers[index],
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _controllers.length > 1
                            ? () => _removeStep(index)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _saveError!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addStep,
                    child: Text(
                      AppStrings.t('add_step_button'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(
                      AppStrings.t('save_button'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
