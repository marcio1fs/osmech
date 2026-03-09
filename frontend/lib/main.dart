import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/checkout_return_page.dart';
import 'widgets/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  String _resolveInitialRoute() {
    final base = Uri.base;
    final fragment = base.fragment.trim();
    final path = base.path.trim();

    if (fragment == '/assinatura/sucesso' ||
        fragment == '/assinatura/pendente' ||
        fragment == '/assinatura/falha') {
      return fragment;
    }

    if (path == '/assinatura/sucesso' ||
        path == '/assinatura/pendente' ||
        path == '/assinatura/falha') {
      return path;
    }

    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSMECH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: _resolveInitialRoute(),
      builder: (context, child) {
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): NextFocusIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              NextFocusIntent: _EnterNextFocusAction(),
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routes: {
        '/': (context) => const _AuthGate(),
        '/assinatura/sucesso': (context) =>
            const CheckoutReturnPage(result: 'sucesso'),
        '/assinatura/pendente': (context) =>
            const CheckoutReturnPage(result: 'pendente'),
        '/assinatura/falha': (context) =>
            const CheckoutReturnPage(result: 'falha'),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const _AuthGate(),
      ),
    );
  }
}

class _EnterNextFocusAction extends Action<NextFocusIntent> {
  @override
  Object? invoke(NextFocusIntent intent) {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return null;

    final focusedWidget = focusedContext.widget;
    final editable = focusedWidget is EditableText
        ? focusedWidget
        : focusedContext.findAncestorWidgetOfExactType<EditableText>();

    if (editable == null) return null;
    if (editable.maxLines != 1 || editable.readOnly) return null;

    FocusScope.of(focusedContext).nextFocus();
    return null;
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.initialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (auth.isAuthenticated) {
          return const AppShell();
        }
        return const LoginPage();
      },
    );
  }
}
