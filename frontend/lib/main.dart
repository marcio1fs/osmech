import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/ordens_servico_page.dart';
import 'pages/form_os_page.dart';
import 'pages/configuracoes_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const OsmechApp());
}

class OsmechApp extends StatelessWidget {
  const OsmechApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSMECH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/ordens_servico': (context) => const OrdensServicoPage(),
        '/form_os': (context) => const FormOsPage(),
        '/configuracoes': (context) => const ConfiguracoesPage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService.getToken();
    setState(() {
      _authenticated = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle, size: 80, color: Colors.blue),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    if (_authenticated) {
      return const DashboardPage();
    } else {
      return const LoginPage();
    }
  }
}
