import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/home_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';

class AppRouter {
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static String initialRoute(AppDependencies dependencies) {
    final session = dependencies.authRepository.currentSession;
    if (session == null) {
      return login;
    }
    return session.onboardingPendente ? onboarding : home;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingPage(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }
}
