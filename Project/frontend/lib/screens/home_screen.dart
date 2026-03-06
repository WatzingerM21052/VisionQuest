import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../models/quest_log_entry.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  /// Behandelt den Logout-Prozess.
  ///
  /// Entfernt den Token, cleant den AppState und navigiert zum Login.
  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      // Username aus AppState entfernen
      ref.read(appStateProvider.notifier).setUsername(null);

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Logout fehlgeschlagen.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = ref.watch(
      appStateProvider.select((state) => state.username),
    );
    final displayName = (username != null && username.isNotEmpty)
        ? username
        : 'Spieler';
    final progress = ref.watch(
      appStateProvider.select((state) => state.progress),
    );
    final logEntries = ref.watch(
      appStateProvider.select((state) => state.logEntries),
    );
    final today = DateTime.now();

    // Heutige Einträge filtern
    final todayEntries = logEntries.where((entry) {
      final t = entry.timestamp;
      return t.year == today.year &&
          t.month == today.month &&
          t.day == today.day;
    }).toList();

    // Daily Quest für heute
    final dailyQuest = _questForDate(today);

    // Stats berechnen
    final totalScanned = todayEntries.length; // Heutige Scans
    final foundToday = _countQuestMatches(
      todayEntries,
      dailyQuest,
    ); // Heutige Quest-Matches
    final totalFound = foundToday; // Nur heutige Daily-Quest Objekte
    final dailyTarget = dailyQuest.requiredCount;
    final questCompleted = foundToday >= dailyTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionQuest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1100;
            final isWideDesktop = width >= 1500;
            final contentWidth = isWideDesktop
                ? 1120.0
                : (isDesktop ? 960.0 : (width > 900 ? 820.0 : 640.0));
            final horizontalPadding = isWideDesktop
                ? 24.0
                : (isDesktop ? 20.0 : 16.0);
            final verticalPadding = isDesktop ? 16.0 : 14.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/Startlogo.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 28),

                      // Welcome Section
                      Text(
                        'Willkommen zurück, $displayName!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dein nächstes Abenteuer wartet...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Streak Counter - Static, no animation
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: theme.textTheme.headlineMedium),
                            const SizedBox(width: 8),
                            Text(
                              'Streak: ${progress.streak} Tag${progress.streak == 1 ? '' : 'e'}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Profile Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.secondary,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stufe ${progress.level}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // XP Progress Bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Erfahrungspunkte',
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      Text(
                                        '${progress.totalXp} / ${progress.nextLevelXp}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // XP Bar with subtle shadow
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress.levelProgress,
                                        minHeight: 8,
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quest Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      dailyQuest.icon,
                                      size: 28,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tägliche Quest',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dailyQuest.description,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Daily Quest Progress
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: questCompleted
                                      ? [
                                          BoxShadow(
                                            color: colorScheme.tertiary
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      questCompleted
                                          ? Icons.check_circle
                                          : Icons.flag,
                                      size: 16,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${dailyQuest.progressLabel}: ${foundToday.clamp(0, dailyTarget)} / $dailyTarget',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color:
                                                colorScheme.onTertiaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              colorScheme,
                              icon: Icons.camera_alt,
                              label: 'Gescannt',
                              value: '$totalScanned',
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              colorScheme,
                              icon: Icons.check_circle,
                              label: 'Gefunden',
                              value: '$totalFound',
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              colorScheme,
                              icon: Icons.star,
                              label: 'Punkte',
                              value: '${progress.totalXp}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Main CTA Button
                      FilledButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.scanner);
                              },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scanner starten'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.questLog);
                              },
                              icon: const Icon(Icons.history),
                              label: const Text('Quest-Log'),
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.settings);
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Einstellungen'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Achievements Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.achievements);
                        },
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Achievements'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Gibt die Daily Quest für ein bestimmtes Datum zurück.
  ///
  /// LEGACY: Diese Funktion wird noch für Home Screen Stats verwendet.
  /// Sollte langfristig durch Scanner Quest System ersetzt werden.
  _DailyQuest _questForDate(DateTime date) {
    const quests = <_DailyQuest>[
      _DailyQuest(
        description: 'Scanne ein Handy.',
        targetLabels: ['cell phone'],
        requiredCount: 1,
        progressLabel: 'Handys erkannt',
        icon: Icons.smartphone,
      ),
      _DailyQuest(
        description: 'Scanne zwei Personen.',
        targetLabels: ['person'],
        requiredCount: 2,
        progressLabel: 'Personen erkannt',
        icon: Icons.groups,
      ),
      _DailyQuest(
        description: 'Scanne eine Tasse oder ein Glas.',
        targetLabels: ['cup', 'bottle', 'wine glass'],
        requiredCount: 1,
        progressLabel: 'Getränke erkannt',
        icon: Icons.local_drink,
      ),
      _DailyQuest(
        description: 'Scanne ein Buch oder Notebook.',
        targetLabels: ['book', 'laptop'],
        requiredCount: 1,
        progressLabel: 'Lernobjekte erkannt',
        icon: Icons.menu_book,
      ),
      _DailyQuest(
        description: 'Scanne drei Alltagsobjekte (Stuhl/Backpack/Uhr).',
        targetLabels: ['chair', 'backpack', 'clock'],
        requiredCount: 3,
        progressLabel: 'Alltagsobjekte erkannt',
        icon: Icons.explore,
      ),
      _DailyQuest(
        description: 'Scanne zwei Tech-Objekte (Maus/Tastatur/Monitor).',
        targetLabels: ['mouse', 'keyboard', 'tv'],
        requiredCount: 2,
        progressLabel: 'Tech-Objekte erkannt',
        icon: Icons.computer,
      ),
    ];

    final dayKey =
        DateTime(
          date.year,
          date.month,
          date.day,
        ).difference(DateTime(2025, 1, 1)).inDays %
        quests.length;
    return quests[dayKey];
  }

  /// Zählt wie viele Quest-Objekte in den Entries gefunden wurden.
  ///
  /// LEGACY: Teil des alten Daily Quest Systems.
  int _countQuestMatches(List<QuestLogEntry> entries, _DailyQuest quest) {
    var matches = 0;
    for (final entry in entries) {
      final normalized = entry.label.toLowerCase();
      final isMatch = quest.targetLabels.any(
        (target) => normalized.contains(target),
      );
      if (isMatch) {
        matches++;
      }
    }
    return matches;
  }

  /// Erstellt eine Stat-Card mit Icon, Wert und Label.
  Widget _buildStatCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer.withValues(alpha: 0.6),
              colorScheme.primaryContainer.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 24, color: colorScheme.secondary),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyQuest {
  const _DailyQuest({
    required this.description,
    required this.targetLabels,
    required this.requiredCount,
    required this.progressLabel,
    required this.icon,
  });

  final String description;
  final List<String> targetLabels;
  final int requiredCount;
  final String progressLabel;
  final IconData icon;
}
