import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../models/app_state.dart';
import '../providers/app_state_provider.dart';

/// Zeigt eine \u00dcbersicht aller Achievements (freigeschaltet und gesperrt).
///
/// Achievements werden nach Type gruppiert:
/// - Object Scan: Erkenne bestimmte Objekte
/// - Milestone: Erreiche Level/XP/Streak Ziele
/// - Meta: Spezielle Achievements (z.B. Completionist)
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = ref.watch(appStateProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= 1100
        ? 4
        : (screenWidth >= 760 ? 3 : 2);
    final childAspectRatio = screenWidth < 420
        ? 0.68
        : (screenWidth < 760 ? 0.74 : 0.86);
    final unlockedAchievements = appState.unlockedAchievements;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), elevation: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Text(
                    'Deine Achievements',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanne Objekte, erreiche Milestones und schalte alle Achievements frei!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
            // Achievements Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final achievement = allAchievements[index];
                  final isUnlocked = unlockedAchievements.contains(
                    achievement.id,
                  );
                  final progressCount = _calculateProgress(
                    achievement: achievement,
                    unlockedAchievements: unlockedAchievements,
                    appState: appState,
                  );

                  return _AchievementCard(
                    achievement: achievement,
                    isUnlocked: isUnlocked,
                    progressCount: progressCount,
                    theme: theme,
                    colorScheme: colorScheme,
                  );
                }, childCount: allAchievements.length),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }

  int _calculateProgress({
    required Achievement achievement,
    required List<String> unlockedAchievements,
    required AppState appState,
  }) {
    switch (achievement.type) {
      case AchievementType.objectScan:
        final label = achievement.objectLabel?.toLowerCase();
        if (label == null) {
          return 0;
        }
        return appState.logEntries
            .where((entry) => entry.label.toLowerCase() == label)
            .length;

      case AchievementType.milestone:
        switch (achievement.id) {
          case 'scanner_master':
            return appState.logEntries.length;
          case 'level_10':
            return appState.progress.level;
          case 'streak_champion':
            return appState.progress.streak;
          case 'xp_collector':
            return appState.progress.totalXp;
          default:
            return 0;
        }

      case AchievementType.meta:
        final nonMetaCount = allAchievements
            .where((a) => a.type != AchievementType.meta)
            .length;
        final unlockedNonMeta = unlockedAchievements
            .where(
              (id) => allAchievements
                  .where((a) => a.type != AchievementType.meta)
                  .any((a) => a.id == id),
            )
            .length;
        return unlockedNonMeta.clamp(0, nonMetaCount);
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final int progressCount;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.progressCount,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.6),
                    colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isUnlocked
                ? colorScheme.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon und Status
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? colorScheme.primaryContainer
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked
                            ? colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  Text(achievement.icon, style: const TextStyle(fontSize: 32)),
                ],
              ),
              const SizedBox(height: 8),

              // Rarität Sterne
              Text(
                achievement.rarity.stars,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),

              // Titel
              Text(
                achievement.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Beschreibung
              Flexible(
                child: Text(
                  achievement.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUnlocked
                        ? colorScheme.onSurfaceVariant
                        : Colors.grey,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(height: 4),
                Text(
                  '${progressCount.clamp(0, achievement.targetCount)}/${achievement.targetCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // Unlock Status
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✓ Freigeschalten',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Gesperrt',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
