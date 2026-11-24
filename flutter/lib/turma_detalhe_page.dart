import 'package:flutter/material.dart';

import 'models.dart';
import 'professor_api.dart';
import 'screens/nfc_instrucao_page.dart';
import 'widgets/nfc_scaffold.dart';
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
    required this.professorApi,
    required this.turma,
    required this.onChanged,
    required this.onDeleted,
    this.nfcService,
  });

  final TurmasApi api;
  final ProfessorApi professorApi;
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

  /// Nome e RA dos matriculados, por ID (`GET /classes/:id/students`).
  Map<String, AlunoChamada> _nomes = {};

  /// Quantos matriculados que não existem mais foram tirados da turma
  /// automaticamente ao abrir esta tela.
  int _removidos = 0;

  /// Erro ao buscar os nomes (ex.: sem conexão).
  String? _avisoAlunos;

  @override
  void initState() {
    super.initState();
    _carregarNomes();
  }

  Future<void> _carregarNomes() async {
    if (_turma.enrolledStudents.isEmpty) {
      if (mounted) setState(() => _nomes = {});
      return;
    }
    try {
      final lista = await widget.professorApi.listaChamada(_turma.id);
      if (!mounted) return;
      setState(() {
        _nomes = {for (final a in lista.alunos) a.id: a};
        _avisoAlunos = null;
      });
      if (lista.ausentes.isNotEmpty) await _removerAusentes(lista.ausentes);
    } on ApiException catch (e) {
      // A lista continua funcionando com os IDs, para dar para remover.
      if (mounted) setState(() => _avisoAlunos = e.message);
    }
  }

  /// Tira da turma os matriculados que o backend diz não existirem mais.
  Future<void> _removerAusentes(List<String> ids) async {
    var turma = _turma;
    for (final id in ids) {
      turma = await widget.api.removerAluno(turma.id, id);
    }
    if (!mounted) return;
    setState(() {
      _turma = turma;
      _removidos = ids.length;
    });
    widget.onChanged(turma);
  }

  void _atualizar(Turma nova) {
    final mudouAlunos =
        nova.enrolledStudents.join(',') != _turma.enrolledStudents.join(',');
    setState(() {
      _turma = nova;
      if (mudouAlunos) _removidos = 0;
    });
    widget.onChanged(nova);
    if (mudouAlunos) _carregarNomes();
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
        content: Text('A turma "${_turma.name}" será removida.'),
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

  /// Abre a chamada (janela de 5 minutos) e deixa o professor encostar os
  /// cartões dos alunos; cada leitura marca o aluno como presente.
  Future<void> _validarPresenca() => _executar(() async {
    await widget.professorApi.abrirChamada(_turma.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      nfcRoute(
        NfcInstrucaoPage(
          nomeDisciplina: _turma.name,
          nfcService: widget.nfcService,
          onValidarPresenca: (uid) async {
            await widget.professorApi.presencaPorNfc(_turma.id, [uid]);
            return true;
          },
        ),
      ),
    );
  });

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
                  _turma.name,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.4,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_turma.week, style: const TextStyle(fontSize: 16)),
                Text(
                  _turma.horario,
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
          Text(
            'Alunos (${_turma.enrolledStudents.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 8),
          if (_removidos > 0 || _avisoAlunos != null)
            Container(
              key: const Key('aviso-alunos'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x22E53935),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _avisoAlunos ??
                    (_removidos == 1
                        ? '1 aluno removido, não encontrado.'
                        : '$_removidos alunos removidos, não encontrados.'),
              ),
            ),
          if (_turma.enrolledStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nenhum aluno matriculado.')),
            )
          else
            for (final id in _turma.enrolledStudents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                // Enquanto os nomes carregam (ou se falharem), mostra o ID.
                title: Text(_nomes[id]?.name ?? 'Aluno $id'),
                subtitle: _nomes[id] == null
                    ? null
                    : Text('RA ${_nomes[id]!.ra}'),
                trailing: IconButton(
                  tooltip: 'Remover ${_nomes[id]?.name ?? id}',
                  onPressed: _ocupado ? null : () => _remover(id),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ),
        ],
      ),
    ),
  );
}
