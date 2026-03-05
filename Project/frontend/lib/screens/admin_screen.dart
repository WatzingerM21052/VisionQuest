import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state_provider.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _adminService = AdminService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _currentTab = 'users'; // 'users' oder 'stats'

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await _authService.storage.readToken();
      if (token == null) {
        throw AdminException('Kein Token gefunden', code: 'NO_TOKEN');
      }

      final users = await _adminService.getAllUsers(token);
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } on AdminException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers
          .where(
            (user) =>
                user.username.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> _editUser(User user) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );

    if (result != null && mounted) {
      await _updateUser(user, result);
    }
  }

  Future<void> _updateUser(User user, Map<String, dynamic> updates) async {
    try {
      final token = await _authService.storage.readToken();
      if (token == null) throw AdminException('Kein Token', code: 'NO_TOKEN');

      await _adminService.updateUser(token, user.id, updates);

      // Update local app state with changes if relevant fields were modified
      if (updates.containsKey('xp') ||
          updates.containsKey('level') ||
          updates.containsKey('username') ||
          updates.containsKey('role')) {
        try {
          final xpValue = updates['xp'];
          final levelValue = updates['level'];
          
          if (xpValue != null && levelValue != null) {
            final parsedXp = xpValue is int ? xpValue : int.tryParse(xpValue.toString());
            final parsedLevel = levelValue is int ? levelValue : int.tryParse(levelValue.toString());

            if (parsedXp != null && parsedLevel != null) {
              ref
                  .read(appStateProvider.notifier)
                  .setProgress(totalXp: parsedXp, level: parsedLevel);
            }
          }

          final updatedUsername = updates['username']?.toString().trim();
          if (updatedUsername != null && updatedUsername.isNotEmpty) {
            ref.read(appStateProvider.notifier).setUsername(updatedUsername);
          }

          final updatedRole = updates['role']?.toString().trim();
          if (updatedRole != null && updatedRole.isNotEmpty) {
            ref.read(appStateProvider.notifier).setUserRole(updatedRole);
          }
        } catch (e) {
          debugPrint('Error updating local state: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User erfolgreich aktualisiert')),
        );
        await _loadUsers();
      }
    } on AdminException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User löschen?'),
        content: Text(
          'Möchtest du den User "${user.username}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _authService.storage.readToken();
      if (token == null) throw AdminException('Kein Token', code: 'NO_TOKEN');

      await _adminService.deleteUser(token, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User erfolgreich gelöscht')),
        );
        await _loadUsers();
      }
    } on AdminException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin-Panel'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Navigation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'users',
                        icon: Icon(Icons.people),
                        label: Text('Benutzer'),
                      ),
                      ButtonSegment(
                        value: 'stats',
                        icon: Icon(Icons.bar_chart),
                        label: Text('Statistiken'),
                      ),
                    ],
                    selected: {_currentTab},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() => _currentTab = selection.first);
                    },
                  ),
                ),
                // Tab Content
                Expanded(
                  child: _currentTab == 'users'
                      ? _buildUserManagementView(context, theme, colorScheme)
                      : _buildStatisticsView(context, theme, colorScheme),
                ),
              ],
            ),
    );
  }

  Widget _buildUserManagementView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          SearchBar(
            controller: _searchController,
            leading: const Icon(Icons.search),
            hintText: 'Benutzer suchen...',
            onChanged: (_) => _filterUsers(),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Count
          Text(
            '${_filteredUsers.length} Benutzer gefunden',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null) const SizedBox(height: 16),

          // User List
          if (_filteredUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Keine Benutzer gefunden',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _UserTile(
                  user: user,
                  onEdit: () => _editUser(user),
                  onDelete: () => _deleteUser(user),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden der Statistiken',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Keine Daten verfügbar'));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Cards
              _buildSummaryCards(stats['summary'] ?? {}, theme, colorScheme),
              const SizedBox(height: 24),

              // Level Distribution
              _buildLevelDistribution(stats['distribution']?['byLevel'] ?? {}, theme, colorScheme),
              const SizedBox(height: 24),

              // Top Users
              _buildTopUsers(stats['topUsers'] ?? [], theme, colorScheme),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStatistics() async {
    final token = await _authService.storage.readToken();
    if (token == null) throw Exception('Kein Token vorhanden');
    return await _adminService.getStats(token);
  }

  Widget _buildSummaryCards(
    Map<String, dynamic> summary,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Übersicht',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Gesamt Benutzer',
              summary['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
              theme,
              colorScheme,
            ),
            _buildStatCard(
              'Aktiv',
              summary['activeUsers']?.toString() ?? '0',
              Icons.thumb_up,
              Colors.green,
              theme,
              colorScheme,
            ),
            _buildStatCard(
              'Inaktiv',
              summary['inactiveUsers']?.toString() ?? '0',
              Icons.thumb_down,
              Colors.orange,
              theme,
              colorScheme,
            ),
            _buildStatCard(
              'Admins',
              summary['adminCount']?.toString() ?? '0',
              Icons.shield,
              Colors.red,
              theme,
              colorScheme,
            ),
            _buildStatCard(
              'Ø Level',
              (summary['averageLevel']?.toString() ?? '0'),
              Icons.trending_up,
              Colors.purple,
              theme,
              colorScheme,
            ),
            _buildStatCard(
              'Gesamt XP',
              summary['totalXp']?.toString() ?? '0',
              Icons.star,
              Colors.amber,
              theme,
              colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDistribution(
    Map<String, dynamic> distribution,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level Verteilung',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (distribution.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Keine Daten verfügbar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: distribution.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entries = distribution.entries.toList();
                final level = int.tryParse(entries[index].key) ?? entries[index].key;
                final count = entries[index].value ?? 0;

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Level $level',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count Benutzer',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTopUsers(
    List<dynamic> topUsers,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Benutzer',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (topUsers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Keine Benutzer gefunden',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topUsers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = topUsers[index] as Map<String, dynamic>;
              final username = user['username'] ?? 'Unbekannt';
              final level = user['level'] ?? 0;
              final xp = user['xp'] ?? 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getMedalColor(index),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username as String,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Level $level • $xp XP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
            },
          ),
      ],
    );
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.role == 'admin'
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: user.role == 'admin' ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Level ${user.level} • XP: ${user.xp}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (!user.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'INAKTIV',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.red,
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
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AKTIV',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Bearbeiten'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Löschen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final User user;

  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _levelController;
  late final TextEditingController _xpController;
  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _levelController = TextEditingController(
      text: widget.user.level.toString(),
    );
    _xpController = TextEditingController(text: widget.user.xp.toString());
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _levelController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-Mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _levelController,
              decoration: const InputDecoration(labelText: 'Level'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _xpController,
              decoration: const InputDecoration(labelText: 'XP'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Rolle'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('User aktiv'),
              value: _isActive,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _isActive = value);
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final updates = <String, dynamic>{
              'username': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'level': int.tryParse(_levelController.text) ?? widget.user.level,
              'xp': int.tryParse(_xpController.text) ?? widget.user.xp,
              'role': _selectedRole,
              'is_active': _isActive ? 1 : 0,
            };
            Navigator.pop(context, updates);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
