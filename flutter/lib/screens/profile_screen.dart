import 'dart:async';

import 'package:flutter/material.dart';

import 'package:identitas/services/api_service.dart';
import 'package:identitas/screens/login_page.dart';
import 'package:identitas/services/models.dart';
import 'package:identitas/services/nfc_service.dart';

/// Perfil de quem está logado (`GET /auth/profile`) e botão de sair.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.auth, this.nfcService});

  final AuthApi? auth;
  final NfcService? nfcService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthApi _auth = widget.auth ?? AuthApi();
  late final NfcService _nfc = widget.nfcService ?? NfcService();
  Usuario? _usuario;
  String? _erro;
  bool _carregando = true;
  bool _vinculandoNfc = false;

  @override
  void dispose() {
    unawaited(_nfc.parar());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool mostrarCarregamento = true}) async {
    setState(() {
      _carregando = mostrarCarregamento;
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

  Future<void> _vincularNfc() async {
    final usuario = _usuario;
    if (usuario == null || _vinculandoNfc) return;
    setState(() => _vinculandoNfc = true);
    try {
      final uid = await _nfc.lerUid();
      final atualizado = await _auth.vincularNfc(usuario.id, uid);
      if (!mounted) return;
      setState(() => _usuario = atualizado);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Cartão NFC vinculado.')));
    } on NfcReadException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _vinculandoNfc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      key: const Key('perfil-voltar'),
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  const Text(
                    'Meu Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_carregando)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFF9FF2E)),
                  ),
                )
              else if (usuario != null)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              _carregar(mostrarCarregamento: false),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                              _DigitalProfileCard(user: usuario),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const Key('perfil-vincular-nfc'),
                                  onPressed: _vinculandoNfc
                                      ? null
                                      : _vincularNfc,
                                  icon: _vinculandoNfc
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.contactless),
                                  label: Text(
                                    _vinculandoNfc
                                        ? 'Aproxime o cartão...'
                                        : usuario.nfcUid == null
                                        ? 'Vincular cartão NFC'
                                        : 'Trocar cartão NFC',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFF9FF2E),
                                    side: const BorderSide(
                                      color: Color(0xFFF9FF2E),
                                    ),
                                  ),
                                ),
                              ),
                              if (usuario.nfcUid != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'NFC UID: ${usuario.nfcUid}',
                                  key: const Key('perfil-nfc-uid'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _logoutButton(),
                    ],
                  ),
                )
              else ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _erro ?? 'Não foi possível carregar o perfil.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('perfil-tentar-novamente'),
                        onPressed: _carregar,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF9FF2E),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                      const Spacer(),
                      _logoutButton(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      key: const Key('perfil-sair'),
      onPressed: _sair,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF9FF2E),
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
      ),
      child: const Text('Sair'),
    ),
  );
}

class _DigitalProfileCard extends StatelessWidget {
  const _DigitalProfileCard({required this.user});

  final Usuario user;

  @override
  Widget build(BuildContext context) {
    final period = user.periodSemester.trim();
    final formattedPeriod = period.isEmpty
        ? 'Não informado'
        : period.toLowerCase().contains('semestre')
        ? period
        : '$periodº semestre';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: const Color(0xFFF9FF2E),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEFFD9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 42,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.ehProfessor ? 'Professor' : 'Aluno',
                    style: const TextStyle(
                      color: Color(0xFFF9FF2E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFFEFFD9),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileField(
                  label: user.ehProfessor ? 'RP (Registro do Professor)' : 'RA',
                  value: user.ra,
                ),
                _ProfileField(
                  label: user.ehProfessor ? 'Escola' : 'Curso',
                  value: user.course.isEmpty ? 'Não informado' : user.course,
                ),
                if (!user.ehProfessor)
                  _ProfileField(label: 'Período', value: formattedPeriod),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
