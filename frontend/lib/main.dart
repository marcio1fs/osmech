import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/checkout_return_page.dart';
import 'pages/aceitar_convite_page.dart';
import 'pages/dois_fa_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/verify_email_page.dart';
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

    // Rotas de assinatura
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

    // Links enviados por e-mail (fragment ou path):
    final fragmentBase = fragment.split('?').first;
    if (fragmentBase == '/aceitar-convite' || path == '/aceitar-convite') {
      return '/aceitar-convite';
    }
    if (fragmentBase == '/reset-password' || path == '/reset-password' ||
        fragment.startsWith('/reset-password') || path.startsWith('/reset-password')) {
      return '/reset-password';
    }
    if (fragmentBase == '/verify-email' || path == '/verify-email') {
      return '/verify-email';
    }
    if (fragmentBase == '/recuperar-senha' || path == '/recuperar-senha' ||
        fragment == '/forgot-password' || path == '/forgot-password') {
      return '/recuperar-senha';
    }

    return '/';
  }

  /// Extrai ?token= da URL atual (path strategy ou hash strategy).
  String _tokenDaUrl() {
    final base = Uri.base;
    final direto = base.queryParameters['token'];
    if (direto != null && direto.isNotEmpty) return direto;
    final frag = base.fragment;
    final q = frag.indexOf('?');
    if (q >= 0 && q + 1 < frag.length) {
      final params = Uri.parse('http://placeholder/?' + frag.substring(q + 1))
          .queryParameters;
      return params['token'] ?? '';
    }
    return '';
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
            SingleActivator(LogicalKeyboardKey.f4): _NavIntent(3),   // Pagamentos
            SingleActivator(LogicalKeyboardKey.f5): _NavIntent(4),   // Assinatura
            SingleActivator(LogicalKeyboardKey.f6): _NavIntent(5),   // Mecânicos
            SingleActivator(LogicalKeyboardKey.f7): _NavIntent(7),   // Financeiro
            SingleActivator(LogicalKeyboardKey.f8): _NavIntent(12),  // Estoque
            SingleActivator(LogicalKeyboardKey.f9): _NavIntent(16),  // IA OSMECH
            SingleActivator(LogicalKeyboardKey.f10): _NavIntent(19), // Relatórios
            SingleActivator(LogicalKeyboardKey.f11): _NavIntent(20), // Administração
            SingleActivator(LogicalKeyboardKey.f12): _NavIntent(17), // Meu Perfil
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
        '/login': (context) => const _AuthGate(),
        '/aceitar-convite': (context) => const AceitarConvitePage(),
        '/recuperar-senha': (context) => const ForgotPasswordPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) =>
            ResetPasswordPage(token: _tokenDaUrl()),
        '/verify-email': (context) => VerifyEmailPage(token: _tokenDaUrl()),
        '/assinatura/sucesso': (context) =>
            const CheckoutReturnPage(result: 'sucesso'),
        '/assinatura/pendente': (context) =>
            const CheckoutReturnPage(result: 'pendente'),
        '/assinatura/falha': (context) =>
            const CheckoutReturnPage(result: 'falha'),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/reset-password')) {
          final uri = Uri.parse(settings.name!);
          String? token = uri.queryParameters['token'];
          
          if (token == null) {
            final fragmentUri = Uri.parse(Uri.base.fragment);
            token = fragmentUri.queryParameters['token'];
          }
          if (token == null || token.isEmpty) {
            token = _tokenDaUrl();
          }
          
          return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(token: token),
            settings: settings,
          );
        }
        return null;
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
        if (auth.requer2fa) {
          // Senha correta, aguardando o código de verificação (Fase 4)
          return const DoisFaPage();
        }
        return const LoginPage();
      },
    );
  }
}
