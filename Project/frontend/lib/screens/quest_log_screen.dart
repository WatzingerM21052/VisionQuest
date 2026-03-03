import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state_provider.dart';

class QuestLogScreen extends ConsumerWidget {
  const QuestLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = ref.watch(
      appStateProvider.select((state) => state.logEntries),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quest-Log')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width > 1200
                ? 1100.0
                : (width > 900 ? 900.0 : 680.0);
            final columns = width >= 1000 ? 4 : (width >= 700 ? 3 : 2);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deine letzten Funde',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${entries.length} Einträge gespeichert',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 56,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Noch keine Funde gespeichert',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Starte einen Scan, um Einträge zu sammeln.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: GridView.builder(
                            itemCount: entries.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: width >= 1000 ? 1.2 : 1.05,
                                ),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Card(
                                elevation: 1.5,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  colorScheme.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Icon(
                                              _iconForLabel(entry.label),
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '+${entry.xp} XP',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSecondaryContainer,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        entry.label,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 14,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _formatTimestamp(
                                                  entry.timestamp,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Confidence ${(entry.confidence * 100).toStringAsFixed(1)}%',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: entry.confidence.clamp(0, 1),
                                          minHeight: 6,
                                          backgroundColor: colorScheme
                                              .surfaceContainerHighest,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                entry.confidence >= 0.75
                                                    ? colorScheme.tertiary
                                                    : colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final dayOnlyNow = DateTime(now.year, now.month, now.day);
    final dayOnlyTs = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final diffDays = dayOnlyNow.difference(dayOnlyTs).inDays;
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');

    if (diffDays == 0) {
      return 'Heute $hh:$mm';
    }
    if (diffDays == 1) {
      return 'Gestern $hh:$mm';
    }
    return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} $hh:$mm';
  }

  IconData _iconForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('person')) return Icons.person;
    if (normalized.contains('bottle')) return Icons.local_drink;
    if (normalized.contains('book')) return Icons.menu_book;
    if (normalized.contains('chair')) return Icons.chair;
    if (normalized.contains('laptop')) return Icons.laptop;
    if (normalized.contains('cup')) return Icons.coffee;
    return Icons.category;
  }
}
