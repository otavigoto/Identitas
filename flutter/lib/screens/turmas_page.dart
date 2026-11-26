import 'package:flutter/material.dart';

import 'package:identitas/services/api_service.dart';
import 'package:identitas/services/nfc_service.dart';
import 'package:identitas/services/models.dart';
import 'package:identitas/screens/turma_detalhe_page.dart';

class TurmasPage extends StatefulWidget {
  const TurmasPage({
    super.key,
    this.api,
    this.professorApi,
    this.nfcService,
    this.periodSemester,
  });

  final TurmasApi? api;
  final ProfessorApi? professorApi;
  final NfcService? nfcService;
  final String? periodSemester;

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  late final TurmasApi _api = widget.api ?? TurmasApi();
  late final PageController _pages = PageController(viewportFraction: 0.86);
  List<Turma> _turmas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool mostrarCarregamento = true}) async {
    setState(() {
      _carregando = mostrarCarregamento;
      _erro = null;
    });
    try {
      final turmas = await _api.listar();
      if (mounted) setState(() => _turmas = turmas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  int _diaIndex(String dia) {
    final normalized = dia
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e');
    const days = [
      'segunda',
      'terca',
      'quarta',
      'quinta',
      'sexta',
      'sabado',
      'domingo',
    ];
    final index = days.indexWhere(normalized.startsWith);
    return index < 0 ? days.length : index;
  }

  List<String> get _dias {
    final dias = _turmas.map((turma) => turma.week).toSet().toList()
      ..sort((a, b) {
        final compare = _diaIndex(a).compareTo(_diaIndex(b));
        return compare == 0 ? a.compareTo(b) : compare;
      });
    return dias;
  }

  List<Turma> _aulasDoDia(String dia) => _turmas
      .where((turma) => turma.week == dia)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  void _atualizar(Turma nova) {
    setState(() {
      _turmas = [for (final turma in _turmas) turma.id == nova.id ? nova : turma];
    });
  }

  void _abrir(Turma turma) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TurmaDetalhePage(
          api: _api,
          professorApi: widget.professorApi ?? ProfessorApi(),
          turma: turma,
          onChanged: _atualizar,
          nfcService: widget.nfcService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dias = _dias;
    final semestre = widget.periodSemester?.trim() ?? '';
    final subtitulo = semestre.isEmpty
        ? 'Horários da semana'
        : semestre.toLowerCase().contains('semestre')
        ? semestre
        : '$semestreº semestre';
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disciplinas Matriculadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _carregar(mostrarCarregamento: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody:
                          !_carregando && _erro == null && dias.isNotEmpty,
                      child: _carregando
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF9FF2E),
                              ),
                            )
                          : _erro != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _erro!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      key: const Key('tentar-novamente'),
                                      onPressed: () => _carregar(),
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : dias.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhuma disciplina encontrada.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : PageView.builder(
                              key: const Key('disciplinas-por-dia'),
                              controller: _pages,
                              itemCount: dias.length,
                              itemBuilder: (context, index) {
                                final dia = dias[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(6, 48, 6, 24),
                                  child: _DiaCard(
                                    dia: dia,
                                    turmas: _aulasDoDia(dia),
                                    onTap: _abrir,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard({
    required this.dia,
    required this.turmas,
    required this.onTap,
  });

  final String dia;
  final List<Turma> turmas;
  final ValueChanged<Turma> onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FF2E),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dia.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFF9FF2E),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: turmas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _DisciplinaCard(
              turma: turmas[index],
              onTap: () => onTap(turmas[index]),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DisciplinaCard extends StatelessWidget {
  const _DisciplinaCard({required this.turma, required this.onTap});

  final Turma turma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFEFFD9),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      key: Key('disciplina-${turma.id}'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turma.horario,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              turma.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${turma.enrolledStudents.length} alunos',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
