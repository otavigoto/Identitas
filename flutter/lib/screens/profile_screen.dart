import 'package:flutter/material.dart';

import '../auth_api.dart';
import '../login_page.dart';
import '../models.dart';
import '../turmas_api.dart' show ApiException;
import 'user_profile_card.dart';

/// Perfil de quem está logado (`GET /auth/profile`) e botão de sair.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.auth});

  final AuthApi? auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthApi _auth = widget.auth ?? AuthApi();
  Usuario? _usuario;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final usuario = await _auth.perfil();
      if (mounted) setState(() => _usuario = usuario);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _sair() async {
    await _auth.logout();
    if (!mounted) return;
    // Limpa toda a pilha de navegação e volta para a tela de Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meu Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_carregando)
                const Center(
                  child: CircularProgressIndicator(color: Colors.yellowAccent),
                )
              else if (usuario != null)
                UserProfileCard(
                  name: usuario.name,
                  role: usuario.ehProfessor ? 'Professor' : 'Aluno',
                )
              else ...[
                Text(
                  _erro ?? 'Não foi possível carregar o perfil.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('perfil-tentar-novamente'),
                  onPressed: _carregar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const Key('perfil-sair'),
                  onPressed: _sair,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Sair',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
