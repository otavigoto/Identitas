import 'package:flutter/material.dart';

import 'screens/nfc_instrucao_page.dart';
import 'screens/nfc_scaffold.dart';
import 'services/nfc_service.dart';
import 'turma.dart';
import 'turma_form_page.dart';
import 'turmas_mock.dart';

/// Detalhe da turma: dados, alunos matriculados, editar e excluir.
///
/// As mudanças são repassadas à lista por [onChanged] e [onDeleted].
class TurmaDetalhePage extends StatefulWidget {
  const TurmaDetalhePage({
    super.key,
    required this.turma,
    required this.onChanged,
    required this.onDeleted,
    this.nfcService,
  });

  final Turma turma;
  final ValueChanged<Turma> onChanged;
  final VoidCallback onDeleted;
  final NfcService? nfcService;

  @override
  State<TurmaDetalhePage> createState() => _TurmaDetalhePageState();
}

class _TurmaDetalhePageState extends State<TurmaDetalhePage> {
  late Turma _turma = widget.turma;

  String _nomeAluno(String ra) {
    for (final a in alunosMock) {
      if (a.ra == ra) return a.nome;
    }
    return 'Aluno $ra';
  }

  void _atualizar(Turma nova) {
    setState(() => _turma = nova);
    widget.onChanged(nova);
  }

  Future<void> _editar() async {
    final editada = await Navigator.of(context).push<Turma>(
      MaterialPageRoute(builder: (_) => TurmaFormPage(turma: _turma)),
    );
    if (editada != null) _atualizar(editada);
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aula?'),
        content: Text('A turma "${_turma.nome}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirmar-excluir'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    // TODO backend: DELETE /classes/:id
    widget.onDeleted();
    Navigator.of(context).pop();
  }

  void _remover(String ra) {
    // TODO backend: DELETE /classes/:id/students/:studentId
    _atualizar(
      _turma.copyWith(
        listaAlunos: _turma.listaAlunos.where((r) => r != ra).toList(),
      ),
    );
  }

  Future<void> _adicionar() async {
    final disponiveis = alunosMock
        .where((a) => !_turma.listaAlunos.contains(a.ra))
        .toList();
    final escolhido = await showModalBottomSheet<Aluno>(
      context: context,
      builder: (ctx) => SafeArea(
        child: disponiveis.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todos os alunos já estão na turma.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Adicionar aluno',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  for (final a in disponiveis)
                    ListTile(
                      title: Text(a.nome),
                      subtitle: Text('RA ${a.ra}'),
                      onTap: () => Navigator.pop(ctx, a),
                    ),
                ],
              ),
      ),
    );
    if (escolhido == null) return;
    // TODO backend: POST /classes/:id/students  { alunoId }
    _atualizar(
      _turma.copyWith(listaAlunos: [..._turma.listaAlunos, escolhido.ra]),
    );
  }

  void _validarPresenca() {
    Navigator.of(context).push(
      nfcRoute(
        NfcInstrucaoPage(
          nomeDisciplina: _turma.disciplina,
          nfcService: widget.nfcService,
          onValidarPresenca: (_) async {
            throw Exception(
              'A validação de presença ainda não está conectada ao servidor.',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Detalhe da aula',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
          color: Color(0xFF1E1E1E),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Editar aula',
          onPressed: _editar,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Excluir aula',
          onPressed: _excluir,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FF2E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _turma.disciplina,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.4,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_turma.nome, style: const TextStyle(fontSize: 16)),
                Text(
                  'Semestre ${_turma.semestre}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('validar-presenca'),
            onPressed: _validarPresenca,
            icon: const Icon(Icons.contactless),
            label: const Text('Validar presença por NFC'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alunos (${_turma.listaAlunos.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('adicionar-aluno'),
                onPressed: _adicionar,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Adicionar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_turma.listaAlunos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nenhum aluno matriculado.')),
            )
          else
            for (final ra in _turma.listaAlunos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_nomeAluno(ra)),
                subtitle: Text('RA $ra'),
                trailing: IconButton(
                  tooltip: 'Remover ${_nomeAluno(ra)}',
                  onPressed: () => _remover(ra),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ),
        ],
      ),
    ),
  );
}
