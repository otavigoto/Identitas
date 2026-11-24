import 'package:flutter/material.dart';
import 'login_page.dart';
import 'screens/cadastro_screen.dart';
import 'screens/carteirinha_screen.dart';
import 'screens/gestao_disciplina_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/home_screen.dart';
import 'screens/revisao_chamada_screen.dart';
import 'services/auth_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Identitas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF9FF2E)),
      scaffoldBackgroundColor: Colors.white,
    ),
    home: const _SessionGate(),
    routes: {
      '/cadastro': (_) => const CadastroScreen(),
      '/inicio-aluno': (_) => const HomeScreen(),
      '/carteirinha': (_) => const CarteirinhaScreen(),
      '/historico': (_) => const HistoricoScreen(),
      '/gestao-disciplina': (_) => const GestaoDisciplinaScreen(),
      '/revisao-chamada': (_) => const RevisaoChamadaScreen(),
    },
  );
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<AuthUser?> _session;

  @override
  void initState() {
    super.initState();
    _session = AuthService().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E1E1E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF9FF2E)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return HomeScreen(nome: user.name, user: user);
      },
    );
  }
}
