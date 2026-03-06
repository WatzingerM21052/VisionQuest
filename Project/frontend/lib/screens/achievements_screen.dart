import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../providers/app_state_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlockedAchievements = ref.watch(
      appStateProvider.select((state) => state.unlockedAchievements),
    );

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
                    'Sammle Achievements indem du verschiedene Objekte erkennst',
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final achievement = allAchievements[index];
                  final isUnlocked = unlockedAchievements.contains(
                    achievement.id,
                  );
                  return _AchievementCard(
                    achievement: achievement,
                    isUnlocked: isUnlocked,
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
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Expanded(
                child: Column(
                  children: [
                    Text(
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
                    if (!isUnlocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        '0/${achievement.targetCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
