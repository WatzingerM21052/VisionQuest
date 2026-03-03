import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sound = true;
  String _themeMode = 'system';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width > 1100 ? 900.0 : (width > 800 ? 760.0 : 620.0);

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
                            subtitle: Text(
                              _themeMode == 'system'
                                  ? 'System'
                                  : (_themeMode == 'light' ? 'Hell' : 'Dunkel'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'light', label: Text('Hell')),
                                ButtonSegment(value: 'system', label: Text('System')),
                                ButtonSegment(value: 'dark', label: Text('Dunkel')),
                              ],
                              selected: {_themeMode},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _themeMode = value.first;
                                });
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
                    Card(
                      child: Column(
                        children: const [
                          ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('Version'),
                            subtitle: Text('VisionQuest 1.0.0'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.security_outlined),
                            title: Text('Datenschutz'),
                            subtitle: Text('Lokale Daten & Kontooptionen'),
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
