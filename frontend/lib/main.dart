import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'widgets/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const OsmechApp(),
    ),
  );
}

/// App principal do OSMECH.
class OsmechApp extends StatelessWidget {
  const OsmechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSMECH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const AppShell();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
