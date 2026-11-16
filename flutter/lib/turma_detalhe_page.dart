import 'package:flutter/material.dart';

import 'screens/nfc_instrucao_page.dart';
import 'screens/nfc_scaffold.dart';
import 'services/nfc_service.dart';
import 'turma.dart';
import 'turma_form_page.dart';
import 'turmas_api.dart';

/// Detalhe da turma: dados, alunos matriculados, editar e excluir.
///
/// As mudanças são repassadas à lista por [onChanged] e [onDeleted].
class TurmaDetalhePage extends StatefulWidget {
  const TurmaDetalhePage({
    super.key,
    required this.api,
    required this.turma,
    required this.onChanged,
    required this.onDeleted,
    this.nfcService,
  });

  final TurmasApi api;
  final Turma turma;
  final ValueChanged<Turma> onChanged;
  final VoidCallback onDeleted;
  final NfcService? nfcService;

  @override
  State<TurmaDetalhePage> createState() => _TurmaDetalhePageState();
}

class _TurmaDetalhePageState extends State<TurmaDetalhePage> {
  late Turma _turma = widget.turma;
  bool _ocupado = false;

  void _atualizar(Turma nova) {
    setState(() => _turma = nova);
    widget.onChanged(nova);
  }

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
  }

  /// Executa uma chamada à API evitando cliques repetidos.
  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } on ApiException catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _editar() async {
    final editada = await Navigator.of(context).push<Turma>(
      MaterialPageRoute(
        builder: (_) => TurmaFormPage(api: widget.api, turma: _turma),
      ),
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
    await _executar(() async {
      await widget.api.excluir(_turma.id);
      widget.onDeleted();
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _remover(String alunoId) => _executar(() async {
    _atualizar(await widget.api.removerAluno(_turma.id, alunoId));
  });

  Future<void> _adicionar() async {
    final alunoId = await showDialog<String>(
      context: context,
      builder: (_) => const _AlunoDialog(),
    );
    if (alunoId == null || alunoId.isEmpty) return;
    await _executar(() async {
      _atualizar(await widget.api.adicionarAluno(_turma.id, alunoId));
    });
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
      bottom: _ocupado
          ? const PreferredSize(
              preferredSize: Size.fromHeight(2),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'Editar aula',
          onPressed: _ocupado ? null : _editar,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Excluir aula',
          onPressed: _ocupado ? null : _excluir,
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
                onPressed: _ocupado ? null : _adicionar,
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
            for (final aluno in _turma.listaAlunos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Aluno $aluno'),
                trailing: IconButton(
                  tooltip: 'Remover $aluno',
                  onPressed: _ocupado ? null : () => _remover(aluno),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ),
        ],
      ),
    ),
  );
}

/// Pede o RA/ID do aluno. Tem o próprio controller para ele ser descartado
/// só depois da animação de saída do diálogo.
class _AlunoDialog extends StatefulWidget {
  const _AlunoDialog();

  @override
  State<_AlunoDialog> createState() => _AlunoDialogState();
}

class _AlunoDialogState extends State<_AlunoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar aluno'),
    content: TextField(
      key: const Key('aluno-id'),
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(hintText: 'RA ou ID do aluno'),
      onSubmitted: (v) => Navigator.pop(context, v.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(
        key: const Key('confirmar-aluno'),
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Adicionar'),
      ),
    ],
  );
}
