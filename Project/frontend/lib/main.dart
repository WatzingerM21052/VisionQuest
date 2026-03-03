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
    final selectedTheme = ref.watch(appStateProvider.select((state) => state.theme));

    return MaterialApp(
      title: 'VisionQuest',
      theme: AppThemes.themeFor(selectedTheme),
      darkTheme: AppThemes.darkThemeFor(selectedTheme),
      themeMode: AppThemes.themeModeFor(selectedTheme),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.scanner: (context) => const ScannerScreen(),
        AppRoutes.questLog: (context) => const QuestLogScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.reward) {
          final args = settings.arguments;
          if (args is VisionResult) {
            return MaterialPageRoute(
              builder: (context) => RewardScreen(result: args),
            );
          }
        }

        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }
}

