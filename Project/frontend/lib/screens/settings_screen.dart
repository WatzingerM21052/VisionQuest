import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../models/app_theme_option.dart';
import '../models/detection_focus_option.dart';
import '../models/detection_model_option.dart';
import '../providers/app_state_provider.dart';

/// Einstellungen-Bildschirm für App-Konfiguration.
///
/// Erlaubt Anpassung von:
/// - Theme (Light/Dark/System)
/// - Detection Model (YOLO/etc.)
/// - Detection Focus (Balanced/Precision/Speed)
/// - Benachrichtigungen und Sound (TODO: noch nicht implementiert)
/// - Admin Panel (nur für Admin-User sichtbar)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // TODO: Diese Settings sind aktuell nur UI - keine Funktionalität
  bool _notifications = true;
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedTheme = ref.watch(
      appStateProvider.select((state) => state.theme),
    );
    final selectedModel = ref.watch(
      appStateProvider.select((state) => state.detectionModel),
    );
    final selectedFocus = ref.watch(
      appStateProvider.select((state) => state.detectionFocus),
    );
    final userRole = ref.watch(
      appStateProvider.select((state) => state.userRole),
    );
    final isAdmin = userRole == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width > 1100
                ? 900.0
                : (width > 800 ? 760.0 : 620.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'App & Profil',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.palette_outlined),
                            title: const Text('Theme'),
                            subtitle: Text(selectedTheme.label),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<AppThemeOption>(
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const WidgetStatePropertyAll<EdgeInsets>(
                                        EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                  textStyle: WidgetStatePropertyAll<TextStyle?>(
                                    theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                segments: const [
                                  ButtonSegment(
                                    value: AppThemeOption.light,
                                    label: Text('Hell'),
                                  ),
                                  ButtonSegment(
                                    value: AppThemeOption.dark,
                                    label: Text('Dunkel'),
                                  ),
                                  ButtonSegment(
                                    value: AppThemeOption.system,
                                    label: Text('System'),
                                  ),
                                  ButtonSegment(
                                    value: AppThemeOption.retroArcade,
                                    label: Text('Retro'),
                                  ),
                                  ButtonSegment(
                                    value: AppThemeOption.adventureMap,
                                    label: Text('Abenteuer'),
                                  ),
                                ],
                                selected: {selectedTheme},
                                onSelectionChanged: (value) {
                                  ref
                                      .read(appStateProvider.notifier)
                                      .setTheme(value.first);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.center_focus_strong),
                            title: const Text('Erkennungsmodus'),
                            subtitle: Text(
                              '${selectedModel.label} · ${selectedFocus.label}',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Modell',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: SegmentedButton<DetectionModelOption>(
                              segments: const [
                                ButtonSegment(
                                  value: DetectionModelOption.yolo,
                                  label: Text('YOLO'),
                                ),
                                ButtonSegment(
                                  value: DetectionModelOption.cocoSsd,
                                  label: Text('COCO-SSD'),
                                ),
                              ],
                              selected: {selectedModel},
                              onSelectionChanged: (value) {
                                ref
                                    .read(appStateProvider.notifier)
                                    .setDetectionModel(value.first);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Fokus',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SegmentedButton<DetectionFocusOption>(
                              segments: const [
                                ButtonSegment(
                                  value: DetectionFocusOption.strict,
                                  label: Text('Strict'),
                                ),
                                ButtonSegment(
                                  value: DetectionFocusOption.balanced,
                                  label: Text('Balanced'),
                                ),
                              ],
                              selected: {selectedFocus},
                              onSelectionChanged: (value) {
                                ref
                                    .read(appStateProvider.notifier)
                                    .setDetectionFocus(value.first);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: _notifications,
                            onChanged: (value) {
                              setState(() {
                                _notifications = value;
                              });
                            },
                            secondary: const Icon(Icons.notifications_outlined),
                            title: const Text('Benachrichtigungen'),
                            subtitle: const Text('Quest-Updates anzeigen'),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            value: _sound,
                            onChanged: (value) {
                              setState(() {
                                _sound = value;
                              });
                            },
                            secondary: const Icon(Icons.volume_up_outlined),
                            title: const Text('Soundeffekte'),
                            subtitle: const Text('Feedback bei Scan-Erfolgen'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Admin Section
                    if (isAdmin) ...[
                      Text(
                        'Admin',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: const Text('Admin-Control Panel'),
                          subtitle: const Text(
                            'Benutzerverwaltung & Statistiken',
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.admin);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Informationen',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          const ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('Version'),
                            subtitle: Text('VisionQuest 1.0.0'),
                          ),
                          const Divider(height: 1),
                          const ListTile(
                            leading: Icon(Icons.security_outlined),
                            title: Text('Datenschutz'),
                            subtitle: Text('Lokale Daten & Kontooptionen'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.shield_outlined,
                              color: userRole == 'admin'
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                            title: const Text('Benutzer-Rolle'),
                            subtitle: Text(userRole ?? 'user'),
                            trailing: userRole == 'admin'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
