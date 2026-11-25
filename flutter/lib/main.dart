import 'package:flutter/material.dart';

import 'package:identitas/services/api_service.dart';
import 'package:identitas/screens/login_page.dart';
import 'package:identitas/styles/app_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se já existe login salvo, abre direto na tela do perfil (aluno/professor).
  final auth = AuthApi();
  final logado = await auth.restaurarSessao();
  runApp(MyApp(home: logado ? telaInicialPara(auth.sessao.role) : null));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  /// Tela inicial; por padrão, o login.
  final Widget? home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Identitas',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: home ?? const LoginPage(),
  );
}

