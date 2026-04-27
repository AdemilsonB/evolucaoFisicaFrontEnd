import 'package:flutter/widgets.dart';

import 'src/app/app_widget.dart';
import 'src/core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.bootstrap();
  runApp(AppWidget(dependencies: dependencies));
}
