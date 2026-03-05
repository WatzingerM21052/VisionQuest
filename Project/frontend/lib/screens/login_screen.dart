import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _useEmail = true; // true für Email, false für Username

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        email: _useEmail ? _emailController.text.trim() : null,
        username: !_useEmail ? _usernameController.text.trim() : null,
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

      // User role in AppState speichern
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

        DateTime? parseDate(dynamic value) {
          if (value == null) return null;
          return DateTime.tryParse(value.toString());
        }

        final totalXp = parseInt(userData['xp'] ?? userData['XP']) ?? 0;
        final level = parseInt(userData['level'] ?? userData['LEVEL']) ?? 1;
        final streak =
            parseInt(userData['streak_days'] ?? userData['STREAK_DAYS']) ?? 0;
        final lastQuestDate = parseDate(
          userData['last_quest_date'] ?? userData['LAST_QUEST_DATE'],
        );

        ref
            .read(appStateProvider.notifier)
            .setProgress(
              totalXp: totalXp,
              level: level,
              streak: streak,
              lastCompletedDate: lastQuestDate,
            );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Login fehlgeschlagen. Bitte erneut versuchen.';
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
                      'Willkommen zurück',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Melde dich an um dein Abenteuer fortzusetzen',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Login Method Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useEmail = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _useEmail
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'E-Mail',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: _useEmail
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useEmail = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: !_useEmail
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Username',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: !_useEmail
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email or Username Field
                    if (_useEmail)
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
                      )
                    else
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        autofillHints: const [AutofillHints.username],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte Username eingeben.';
                          }
                          if (value.length < 3) {
                            return 'Username muss mindestens 3 Zeichen lang sein.';
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

                    // Login Button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                          : const Text('Anmelden'),
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

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Noch kein Konto?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Text(
                            'Jetzt registrieren',
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
