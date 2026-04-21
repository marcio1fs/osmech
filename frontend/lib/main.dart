import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/checkout_return_page.dart';
import 'widgets/app_shell.dart';
import 'widgets/upper_text.dart';
import 'theme/app_theme.dart';

/// Notifier global para navegação por atalho de teclado.
final globalNavNotifier = ValueNotifier<int?>(null);

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
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.dark,
      initialRoute: _resolveInitialRoute(),
      builder: (context, child) {
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            // Enter avança foco em campos de texto simples
            SingleActivator(LogicalKeyboardKey.enter): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): NextFocusIntent(),
            // Navegação global entre módulos
            SingleActivator(LogicalKeyboardKey.f1): _NavIntent(0),   // Dashboard
            SingleActivator(LogicalKeyboardKey.f2): _NavIntent(1),   // OS
            SingleActivator(LogicalKeyboardKey.f3): _NavIntent(2),   // Nova OS
            SingleActivator(LogicalKeyboardKey.f4): _NavIntent(5),   // Mecânicos
            SingleActivator(LogicalKeyboardKey.f6): _NavIntent(6),   // Financeiro
            SingleActivator(LogicalKeyboardKey.f7): _NavIntent(11),  // Estoque
            SingleActivator(LogicalKeyboardKey.f8): _NavIntent(15),  // IA
            SingleActivator(LogicalKeyboardKey.f9): _NavIntent(18),  // Relatórios
            SingleActivator(LogicalKeyboardKey.f10): _NavIntent(16), // Perfil
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              NextFocusIntent: _EnterNextFocusAction(),
              _NavIntent: _NavAction(),
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

/// Intent para navegação global por tecla de função.
class _NavIntent extends Intent {
  final int pageIndex;
  const _NavIntent(this.pageIndex);
}

/// Action que notifica o AppShell para trocar de página via ValueNotifier global.
class _NavAction extends Action<_NavIntent> {
  @override
  Object? invoke(_NavIntent intent) {
    globalNavNotifier.value = intent.pageIndex;
    // Reset para permitir navegar para o mesmo índice novamente
    Future.microtask(() => globalNavNotifier.value = null);
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
          return const UpperCaseScope(enabled: true, child: AppShell());
        }
        return const LoginPage();
      },
    );
  }
}
