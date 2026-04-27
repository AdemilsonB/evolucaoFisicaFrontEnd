import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../core/di/app_scope.dart';
import '../core/theme/app_theme.dart';
import 'app_router.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'Evolucao Fisica',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRouter.initialRoute(dependencies),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
