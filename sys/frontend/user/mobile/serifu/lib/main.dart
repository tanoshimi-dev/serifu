import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/platform_init_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await dotenv.load(fileName: '.env.web');
  } else {
    await dotenv.load();
  }
  await platformInitService.initialize(widgetsBinding);

  // Restore auth before running app so router can check sync state
  final loggedIn = await authService.isLoggedIn();
  if (loggedIn) {
    await authService.restoreAuth();
  }
  platformInitService.removeSplash();

  runApp(const SerifuApp());
}

class SerifuApp extends StatelessWidget {
  const SerifuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Serifu - Quiz + SNS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}
