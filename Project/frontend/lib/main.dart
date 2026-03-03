import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/quest_log_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'services/vision_service.dart';
import 'theme/app_themes.dart';

void main() {
  runApp(const ProviderScope(child: VisionQuestApp()));
}

class VisionQuestApp extends ConsumerWidget {
  const VisionQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(
      appStateProvider.select((state) => state.theme),
    );

    return MaterialApp(
      title: 'VisionQuest',
      theme: AppThemes.themeFor(selectedTheme),
      darkTheme: AppThemes.darkThemeFor(selectedTheme),
      themeMode: AppThemes.themeModeFor(selectedTheme),
      initialRoute: AppRoutes.login,
      onGenerateRoute: _buildAnimatedRoute,
    );
  }

  Route<dynamic> _buildAnimatedRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case AppRoutes.login:
        page = const LoginScreen();
      case AppRoutes.register:
        page = const RegisterScreen();
      case AppRoutes.home:
        page = const HomeScreen();
      case AppRoutes.scanner:
        page = const ScannerScreen();
      case AppRoutes.questLog:
        page = const QuestLogScreen();
      case AppRoutes.settings:
        page = const SettingsScreen();
      case AppRoutes.reward:
        final args = settings.arguments;
        if (args is VisionResult) {
          page = RewardScreen(result: args);
        } else {
          page = const LoginScreen();
        }
      default:
        page = const LoginScreen();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right for all routes
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
