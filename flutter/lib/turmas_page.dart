import 'package:flutter/material.dart';

import 'turma.dart';
import 'turma_detalhe_page.dart';
import 'turma_form_page.dart';
import 'turmas_mock.dart';

/// Lista de aulas (turmas) do professor, com busca e filtro por semestre.
class TurmasPage extends StatefulWidget {
  const TurmasPage({super.key});

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  // TODO backend: carregar com GET /classes/teacher/:teacherId
  List<Turma> _turmas = criarTurmasMock();
  String _busca = '';
  String? _semestre;

  List<String> get _semestres =>
      (_turmas.map((t) => t.semestre).toSet().toList()..sort()).reversed
          .toList();

  List<Turma> get _filtradas {
    final q = _busca.trim().toLowerCase();
    return _turmas.where((t) {
      if (_semestre != null && t.semestre != _semestre) return false;
      return q.isEmpty ||
          t.nome.toLowerCase().contains(q) ||
          t.disciplina.toLowerCase().contains(q);
    }).toList();
  }

  void _atualizar(Turma nova) => setState(() {
    _turmas = [for (final t in _turmas) t.id == nova.id ? nova : t];
  });

  void _remover(Turma turma) => setState(() {
    _turmas = _turmas.where((t) => t.id != turma.id).toList();
  });

  Future<void> _nova() async {
    final criada = await Navigator.of(
      context,
    ).push<Turma>(MaterialPageRoute(builder: (_) => const TurmaFormPage()));
    if (criada != null) setState(() => _turmas = [..._turmas, criada]);
  }

  void _abrir(Turma turma) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TurmaDetalhePage(
        turma: turma,
        onChanged: _atualizar,
        onDeleted: () => _remover(turma),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    // Se o semestre filtrado deixou de existir (ex.: turma excluída), limpa.
    if (_semestre != null && !_semestres.contains(_semestre)) _semestre = null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Minhas aulas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nova-aula'),
        onPressed: _nova,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova aula'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: TextField(
                key: const Key('busca-aula'),
                onChanged: (v) => setState(() => _busca = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou disciplina',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final s in _semestres)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: _semestre == s,
                        selectedColor: const Color(0xFFF9FF2E),
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        onSelected: (sel) =>
                            setState(() => _semestre = sel ? s : null),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(child: Text('Nenhuma aula encontrada.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                      itemCount: lista.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TurmaCard(
                        turma: lista[i],
                        onTap: () => _abrir(lista[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurmaCard extends StatelessWidget {
  const _TurmaCard({required this.turma, required this.onTap});

  final Turma turma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF9FF2E),
    borderRadius: BorderRadius.circular(30),
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turma.disciplina,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.2,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(turma.nome),
                  Text(
                    'Semestre ${turma.semestre} · '
                    '${turma.listaAlunos.length} alunos',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
