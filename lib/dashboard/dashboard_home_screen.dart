import 'package:flutter/material.dart';

import 'dashboard_data.dart';
import 'dashboard_theme.dart';
import 'widgets/accuracy_trend_chart.dart';
import 'widgets/game_summary_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPatients();
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

  Future<void> _loadSnapshot(Patient patient) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await DashboardDataService.fetchSnapshot(patient);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load data for ${patient.name}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.background,
      // SafeArea deliberately doesn't wrap the whole body — the hero
      // banner is meant to bleed behind the status bar for a full-bleed
      // look, rather than leaving a plain background-colored gap above a
      // banner that starts too low. Its own padding accounts for the
      // status bar height directly instead.
      body: RefreshIndicator(
        onRefresh: () => _selectedPatient == null
            ? _loadPatients()
            : _loadSnapshot(_selectedPatient!),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // These 3 states have no hero banner, so they stay safely inset as
    // usual — only the loaded-content state below deliberately bleeds its
    // banner behind the status bar.
    if (_isLoading && _snapshot == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
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
              style: const TextStyle(color: DashboardColors.inkMuted),
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
              style: TextStyle(color: DashboardColors.inkMuted),
            ),
          ],
        ),
      );
    }

    final snapshot = _snapshot!;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroHeader(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    color: DashboardColors.primary,
                    value: snapshot.sessionsLast7Days,
                    label: 'Rounds this week',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AccuracyTrendChart(points: snapshot.last7DayTrend),
              const SizedBox(height: 16),
              const Text(
                'By game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.ink,
                ),
              ),
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

  Widget _buildHeroHeader(BuildContext context) {
    final patient = _selectedPatient!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashboardColors.primary, DashboardColors.primaryDeep],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Smriti — Caregiver Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          if (_patients.length > 1)
            DropdownButton<Patient>(
              value: _selectedPatient,
              underline: const SizedBox.shrink(),
              dropdownColor: DashboardColors.primaryDeep,
              iconEnabledColor: Colors.white,
              items: _patients
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadSnapshot(_selectedPatient!),
          ),
        ],
      ),
    );
  }
}
