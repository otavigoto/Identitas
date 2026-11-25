import 'dart:async';

import 'package:flutter/material.dart';

import 'package:identitas/services/api_service.dart';
import 'package:identitas/services/models.dart';
import 'package:identitas/screens/turma_detalhe_page.dart';
import 'package:identitas/screens/turmas_page.dart';
import 'package:identitas/screens/profile_screen.dart';

class ProfessorHomePage extends StatefulWidget {
  const ProfessorHomePage({super.key, this.api, this.turmasApi});

  final ProfessorApi? api;
  final TurmasApi? turmasApi;

  @override
  State<ProfessorHomePage> createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  late final ProfessorApi _api = widget.api ?? ProfessorApi();
  late final TurmasApi _turmasApi = widget.turmasApi ?? TurmasApi();

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

  Aula? get _proximaAula {
    final agora = TimeOfDay.now();
    final agoraEmMinutos = agora.hour * 60 + agora.minute;
    for (final aula in _hoje?.aulas ?? const <Aula>[]) {
      if ((aula.fimEmMinutos ?? 0) >= agoraEmMinutos) return aula;
    }
    return null;
  }

  void _abrirPerfil() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));

  void _abrirDisciplinas() => Navigator.of(
    context,
  ).push(
    MaterialPageRoute(
      builder: (_) => TurmasPage(
        periodSemester: _hoje?.usuario.periodSemester,
      ),
    ),
  );

  void _abrirGestao(Aula aula) {
    final turma = Turma(
      id: aula.id,
      name: aula.name,
      idProfessor: aula.idProfessor,
      week: aula.week,
      startTime: aula.startTime,
      endTime: aula.endTime,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TurmaDetalhePage(
          api: _turmasApi,
          professorApi: _api,
          turma: turma,
          onChanged: (_) => unawaited(_carregar()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _hoje?.usuario.name ?? ApiClient.instance.session.name ?? '';
    final aulas = _hoje?.aulas ?? const <Aula>[];
    final proximaAula = _proximaAula;

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
              const SizedBox(height: 12),
              const Text(
                'Próxima Aula',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_carregando)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                )
              else if (_erro != null)
                _ErroHome(mensagem: _erro!, onTentar: _carregar)
              else
                _ProximaAulaCard(
                  aula: proximaAula,
                  onTap: proximaAula == null
                      ? null
                      : () => _abrirGestao(proximaAula),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Resumo de Hoje',
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
              if (!_carregando && _erro == null && aulas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhuma aula hoje.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else if (!_carregando && _erro == null)
                for (final aula in aulas) ...[
                  _AulaCard(
                    aula: aula,
                    onTap: () => _abrirGestao(aula),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AulaCard extends StatelessWidget {
  const _AulaCard({required this.aula, required this.onTap});

  final Aula aula;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      key: Key('professor-disciplina-${aula.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFFD9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              aula.horario,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              aula.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12),
                const SizedBox(width: 4),
                Text(aula.week, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProximaAulaCard extends StatelessWidget {
  const _ProximaAulaCard({required this.aula, required this.onTap});

  final Aula? aula;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aula = this.aula;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: aula == null ? null : Key('professor-proxima-${aula.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 168,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FF2E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: aula == null
              ? const Center(
                  child: Text(
                    'Nenhuma aula pendente hoje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'HOJE · ${aula.horario}',
                        style: const TextStyle(
                          color: Color(0xFFF9FF2E),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        aula.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13),
                        const SizedBox(width: 4),
                        Text(aula.week, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
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
