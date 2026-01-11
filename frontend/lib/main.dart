import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'services/auth_service.dart';
import 'pages.pricing_page.dart';

void main() {
  runApp(const OsmechApp());
}

class OsmechApp extends StatelessWidget {
  const OsmechApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSMECH',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/plans': (context) => const PricingPage(),
        '/oficinas': (context) => const OficinasPage(),
        '/os': (context) => const OrdemServicoPage(),
        '/os_form': (context) => const OrdemServicoFormPage(),
        '/oficina_form': (context) => const OficinaFormPage(),
        '/plan_form': (context) => const PlanFormPage(),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authenticated) {
      return const DashboardPage();
    } else {
      return const LoginPage();
    }
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        final role = AuthService.getRoleFromToken(token);
        final isAdmin = role == 'admin';
        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('Bem-vindo ao OSMECH!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.business),
                        label: const Text('Oficinas'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/oficinas');
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Planos'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/plans');
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build),
                        label: const Text('Ordens de Serviço'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/os');
                        },
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Cadastrar Usuário'),
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
