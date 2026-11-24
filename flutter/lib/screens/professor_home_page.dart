import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../professor_api.dart';
import '../turmas_page.dart';
import 'profile_screen.dart';

class ProfessorHomePage extends StatefulWidget {
  const ProfessorHomePage({super.key, this.api});

  final ProfessorApi? api;

  @override
  State<ProfessorHomePage> createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  late final ProfessorApi _api = widget.api ?? ProfessorApi();

  AulasDoDia? _hoje;
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
      final hoje = await _api.aulasDeHoje();
      if (mounted) setState(() => _hoje = hoje);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirPerfil() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));

  void _abrirDisciplinas() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const TurmasPage()));

  @override
  Widget build(BuildContext context) {
    final nome = _hoje?.usuario.name ?? ApiClient.instance.session.name ?? '';
    final aulas = _hoje?.aulas ?? const <Aula>[];

    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregar,
          color: _ink,
          backgroundColor: _accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Olá,\n$nome',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  Material(
                    color: _accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('professor-abrir-perfil'),
                      customBorder: const CircleBorder(),
                      onTap: _abrirPerfil,
                      child: const SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(Icons.person_outline, size: 38),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Identitas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Aulas de hoje',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('professor-ver-todas-aulas'),
                    onPressed: _abrirDisciplinas,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'ver todas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                )
              else if (_erro != null)
                _ErroHome(mensagem: _erro!, onTentar: _carregar)
              else if (aulas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhuma aula hoje.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                for (final aula in aulas) ...[
                  _AulaCard(aula: aula),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('professor-ver-todas'),
                onPressed: _abrirDisciplinas,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _ink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Ver todas as disciplinas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AulaCard extends StatelessWidget {
  const _AulaCard({required this.aula});

  final Aula aula;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFFEFFD9),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aula.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('${aula.week} · ${aula.horario}'),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class _ErroHome extends StatelessWidget {
  const _ErroHome({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(mensagem, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      TextButton(
        onPressed: onTentar,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFF9FF2E)),
        child: const Text('Tentar novamente'),
      ),
    ],
  );
}
