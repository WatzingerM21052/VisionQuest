import 'package:flutter/material.dart';

class QuestLogScreen extends StatelessWidget {
  const QuestLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final entries = [
      ('person', '+68 XP', 'Heute 14:05', Icons.person),
      ('bottle', '+51 XP', 'Heute 13:20', Icons.local_drink),
      ('book', '+74 XP', 'Heute 10:42', Icons.menu_book),
      ('chair', '+46 XP', 'Gestern 19:31', Icons.chair),
      ('laptop', '+79 XP', 'Gestern 16:11', Icons.laptop),
      ('cup', '+39 XP', 'Gestern 08:55', Icons.coffee),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quest-Log')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width > 1200 ? 1100.0 : (width > 900 ? 900.0 : 680.0);
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
                      Expanded(
                        child: GridView.builder(
                          itemCount: entries.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final item = entries[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item.$4,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.$1.toUpperCase(),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$2,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$3,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
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
}
