import 'dart:async';

import 'package:flutter/material.dart';

import 'dashboard_data.dart';
import 'dashboard_theme.dart';
import 'widgets/accuracy_trend_chart.dart';
import 'widgets/cognitive_trend_card.dart';
import 'widgets/game_summary_card.dart';
import 'widgets/recent_activity_feed.dart';
import 'widgets/reminder_section.dart';
import 'widgets/stat_card.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  DashboardSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;
  DateTime _now = DateTime.now();

  // Two separate timers rather than one: _tickTimer just repaints "3s ago"
  // / "just now" labels using the wall clock, which is nearly free and
  // needs to happen every second to feel live; _pollTimer is the one that
  // actually re-hits Supabase, on a much longer interval so an idle
  // dashboard left open during a demo doesn't hammer the database.
  Timer? _tickTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_selectedPatient != null) _loadSnapshot(_selectedPatient!, silent: true);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final patients = await DashboardDataService.fetchPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _selectedPatient = patients.isNotEmpty ? patients.first : null;
      });
      if (_selectedPatient != null) {
        await _loadSnapshot(_selectedPatient!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not reach Supabase: $e';
      });
    }
  }

  // [silent] skips the loading-spinner state change — used by the
  // background poll timer so a routine auto-refresh never flashes the
  // whole dashboard back to a spinner while someone's looking at it.
  Future<void> _loadSnapshot(Patient patient, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await DashboardDataService.fetchSnapshot(patient);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _now = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      // A silent background poll failing (e.g. a momentary network blip)
      // shouldn't rip away a perfectly good, already-displayed snapshot —
      // only a foreground load shows the error state.
      if (!silent) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load data for ${patient.name}: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: RefreshIndicator(
        color: DashboardColors.live,
        backgroundColor: DashboardColors.surface,
        onRefresh: () => _selectedPatient == null
            ? _loadPatients()
            : _loadSnapshot(_selectedPatient!),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // These 3 states have no hero header, so they stay safely inset as
    // usual — only the loaded-content state below deliberately bleeds its
    // header behind the status bar.
    if (_isLoading && _snapshot == null) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: DashboardColors.live),
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.cloud_off_rounded, size: 48, color: DashboardColors.warning),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: DashboardTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: _loadPatients,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.person_off_rounded, size: 48, color: DashboardColors.inkMuted),
            SizedBox(height: 16),
            Text(
              'No patients have synced yet. Once someone plays a round on '
              'their phone, they\'ll show up here.',
              textAlign: TextAlign.center,
              style: DashboardTextStyles.bodyMuted,
            ),
          ],
        ),
      );
    }

    final snapshot = _snapshot!;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroHeader(context, snapshot),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CognitiveTrendCard(trend: snapshot.cognitiveTrend),
              const SizedBox(height: 16),
              _responsiveCardRow(
                context,
                spacing: 16,
                minCardWidth: 150,
                cards: [
                  StatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: DashboardColors.streak,
                    value: snapshot.dayStreak,
                    label: 'Day streak',
                  ),
                  StatCard(
                    icon: Icons.trending_up_rounded,
                    color: DashboardColors.good,
                    value: (snapshot.last7DayAccuracy * 100).round(),
                    suffix: '%',
                    label: '7-day accuracy',
                  ),
                  StatCard(
                    icon: Icons.sports_esports_rounded,
                    color: DashboardColors.accent,
                    value: snapshot.sessionsLast7Days,
                    label: 'Rounds this week',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AccuracyTrendChart(points: snapshot.last7DayTrend),
              const SizedBox(height: 16),
              RecentActivityFeed(entries: snapshot.recentActivity, now: _now),
              const SizedBox(height: 16),
              const Text('BY GAME', style: DashboardTextStyles.label),
              const SizedBox(height: 12),
              _responsiveCardRow(
                context,
                spacing: 12,
                minCardWidth: 130,
                cards: [
                  for (final summary in snapshot.gameSummaries)
                    GameSummaryCard(summary: summary),
                ],
              ),
              const SizedBox(height: 16),
              ReminderSection(
                upcoming: snapshot.upcomingReminders,
                missed: snapshot.missedReminders,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lays cards out in as many equal-width columns as fit (at least
  // minCardWidth each), letting every card size to its own content height
  // instead of forcing a fixed aspect ratio — text that wraps to an extra
  // line just makes that row taller, rather than overflowing a rigid box.
  Widget _responsiveCardRow(
    BuildContext context, {
    required List<Widget> cards,
    required double spacing,
    required double minCardWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / (minCardWidth + spacing))
            .floor()
            .clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context, DashboardSnapshot snapshot) {
    final patient = _selectedPatient!;
    final secondsSinceSync = _now.difference(snapshot.fetchedAt).inSeconds;
    final syncedLabel = secondsSinceSync < 3
        ? 'synced just now'
        : secondsSinceSync < 60
            ? 'synced ${secondsSinceSync}s ago'
            : 'synced ${secondsSinceSync ~/ 60}m ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: DashboardColors.surface,
        border: Border(bottom: BorderSide(color: DashboardColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DashboardColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    color: DashboardColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTextStyles.headline,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LivePulseDot(),
                      const SizedBox(width: 6),
                      Text(syncedLabel, style: DashboardTextStyles.monoSmall),
                    ],
                  ),
                ],
              ),
            ),
            if (_patients.length > 1)
              DropdownButton<Patient>(
                value: _selectedPatient,
                underline: const SizedBox.shrink(),
                dropdownColor: DashboardColors.surfaceRaised,
                iconEnabledColor: DashboardColors.inkMuted,
                style: DashboardTextStyles.body,
                items: _patients
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (patient) {
                  if (patient == null) return;
                  setState(() => _selectedPatient = patient);
                  _loadSnapshot(patient);
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: DashboardColors.inkMuted),
              onPressed: () => _loadSnapshot(_selectedPatient!),
            ),
          ],
        ),
      ),
    );
  }
}

// A slow breathing dot next to the "synced Xs ago" label — the same
// visual shorthand as a "live" badge on a broadcast or monitoring
// dashboard, reinforcing that the number beside it is still ticking, not
// a screenshot.
class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: DashboardColors.live,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
