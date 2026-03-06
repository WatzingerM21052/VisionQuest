import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // Username in AppState speichern
      final username = result.username;
      if (username != null && username.isNotEmpty) {
        ref.read(appStateProvider.notifier).setUsername(username);
      }

      final role = result.userRole;
      if (role != null && role.isNotEmpty) {
        ref.read(appStateProvider.notifier).setUserRole(role);
      }

      final userData = result.data?['user'];
      if (userData is Map) {
        int? parseInt(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          return int.tryParse(value.toString());
        }

        final totalXp = parseInt(userData['xp'] ?? userData['XP']) ?? 0;
        final level = parseInt(userData['level'] ?? userData['LEVEL']) ?? 1;
        final streak =
            parseInt(userData['streak_days'] ?? userData['STREAK_DAYS']) ?? 0;

        ref
            .read(appStateProvider.notifier)
            .setProgress(totalXp: totalXp, level: level, streak: streak);
      }

      // Lade Detection History nach erfolgreichem Register
      await ref.read(appStateProvider.notifier).loadStoredEntries();

      // Lade Achievements nach erfolgreichem Register
      await ref.read(appStateProvider.notifier).loadAchievements();

      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Registrierung fehlgeschlagen. Bitte erneut versuchen.';
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/Startlogo.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    Text(
                      'Konto erstellen',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tritt VisionQuest bei und finde geheime Objekte',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Benutzername',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      autofillHints: const [AutofillHints.username],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte Benutzername eingeben.';
                        }
                        if (value.trim().length < 3) {
                          return 'Benutzername muss mindestens 3 Zeichen haben.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte E-Mail eingeben.';
                        }
                        if (!value.contains('@')) {
                          return 'Bitte eine gültige E-Mail eingeben.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: !_showPassword,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort eingeben.';
                        }
                        if (value.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen haben.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Passwort bestätigen',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirm = !_showConfirm;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: !_showConfirm,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort bestätigen.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwörter stimmen nicht überein.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colorScheme.error),
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
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Register Button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Registrieren'),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'oder',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bereits ein Konto?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Zum Login',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
