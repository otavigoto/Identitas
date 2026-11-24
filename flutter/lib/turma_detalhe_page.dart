import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'professor_api.dart';
import 'services/nfc_service.dart';
import 'turma.dart';
import 'turma_form_page.dart';
import 'turmas_api.dart';

/// Gestão da disciplina: frequência da turma, lista de alunos e chamada.
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
  late final NfcService _nfc = widget.nfcService ?? NfcService();
  bool _ocupado = false;
  bool _carregando = true;
  bool _chamadaEmAndamento = false;
  bool _lendoNfc = false;
  bool _scannerPausado = false;
  Map<String, AlunoChamada> _alunos = {};
  Map<String, bool> _presencas = {};
  Map<String, Frequencia> _frequencias = {};
  Frequencia? _frequenciaGeral;
  String? _avisoAlunos;
  String? _avisoNfc;
  int _removidos = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    unawaited(_nfc.parar());
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _avisoAlunos = null;
    });
    try {
      final lista = await widget.professorApi.listaChamada(_turma.id);
      if (!mounted) return;
      setState(() {
        _alunos = {for (final aluno in lista.alunos) aluno.id: aluno};
        _presencas = {
          for (final aluno in lista.alunos) aluno.id: aluno.present,
        };
        _avisoAlunos = null;
      });

      final resumo = await widget.professorApi.resumoFrequencia(_turma.id);
      if (!mounted) return;
      final attendance = resumo['attendance'];
      final alunosResumo = resumo['students'] as List<dynamic>? ?? const [];
      setState(() {
        _frequenciaGeral = attendance is Map<String, dynamic>
            ? Frequencia.fromJson(attendance)
            : null;
        _frequencias = {
          for (final item in alunosResumo)
            if (item is Map<String, dynamic> &&
                item['attendance'] is Map<String, dynamic>)
              item['id'] as String: Frequencia.fromJson(
                item['attendance'] as Map<String, dynamic>,
              ),
        };
      });

      if (lista.ausentes.isNotEmpty) {
        await _removerAusentes(lista.ausentes);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _avisoAlunos = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _removerAusentes(List<String> ids) async {
    var turma = _turma;
    for (final id in ids) {
      turma = await widget.api.removerAluno(turma.id, id);
    }
    if (!mounted) return;
    setState(() {
      _turma = turma;
      _removidos += ids.length;
      for (final id in ids) {
        _presencas.remove(id);
      }
    });
    widget.onChanged(turma);
  }

  Future<void> _removerAluno(String alunoId) async {
    try {
      final turma = await widget.api.removerAluno(_turma.id, alunoId);
      if (!mounted) return;
      setState(() {
        _turma = turma;
        _alunos.remove(alunoId);
        _presencas.remove(alunoId);
        _frequencias.remove(alunoId);
      });
      widget.onChanged(turma);
    } on ApiException catch (e) {
      _erro(e);
    }
  }

  void _erro(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error is ApiException ? error.message : '$error'),
        ),
      );
  }

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
    if (editada == null || !mounted) return;
    setState(() => _turma = editada);
    widget.onChanged(editada);
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir disciplina?'),
        content: Text('A disciplina "${_turma.name}" será removida.'),
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

  Future<void> _validarPresenca() async {
    if (_ocupado) return;
    if (_turma.enrolledStudents.isEmpty) {
      _erro('Matricule alunos antes de iniciar a chamada.');
      return;
    }
    await _executar(() async {
      await widget.professorApi.abrirChamada(_turma.id);
      if (!mounted) return;
      setState(() {
        _chamadaEmAndamento = true;
        _scannerPausado = false;
        _avisoNfc = null;
      });
      if (!await _nfc.estaDisponivel()) {
        setState(() {
          _scannerPausado = true;
          _avisoNfc =
              'NFC indisponível neste dispositivo. Ajuste a presença manualmente.';
        });
        return;
      }
      _armarLeitura();
    });
  }

  void _armarLeitura() {
    if (!mounted || !_chamadaEmAndamento || _scannerPausado || _lendoNfc) {
      return;
    }
    setState(() {
      _lendoNfc = true;
    });
    unawaited(
      _nfc
          .lerCartao(
            onTagLida: (tag) {
              if (!mounted || !_chamadaEmAndamento) return;
              setState(() => _lendoNfc = false);
              final uid = NfcService.uidDoTag(tag);
              if (uid == null) {
                setState(
                  () => _avisoNfc = 'Não foi possível identificar o cartão.',
                );
              } else {
                _registrarCartao(uid);
              }
              Future<void>.delayed(const Duration(milliseconds: 350), () {
                if (mounted) _armarLeitura();
              });
            },
            onErro: () {
              if (!mounted || !_chamadaEmAndamento) return;
              setState(() {
                _lendoNfc = false;
                _scannerPausado = true;
                _avisoNfc = 'Falha ao ler NFC. Tente retomar a leitura.';
              });
            },
          )
          .catchError((Object error) {
            if (!mounted || !_chamadaEmAndamento) return;
            setState(() {
              _lendoNfc = false;
              _scannerPausado = true;
              _avisoNfc = 'Falha ao iniciar a leitura NFC: $error';
            });
          }),
    );
  }

  void _registrarCartao(String uid) {
    final normalizedUid = uid.trim().replaceAll(':', '').toUpperCase();
    AlunoChamada? encontrado;
    for (final aluno in _alunos.values) {
      if (aluno.nfcUid?.trim().replaceAll(':', '').toUpperCase() ==
          normalizedUid) {
        encontrado = aluno;
        break;
      }
    }
    if (encontrado == null) {
      setState(() => _avisoNfc = 'Cartão não vinculado a um aluno da turma.');
      return;
    }
    if (_presencas[encontrado.id] == true) {
      setState(() => _avisoNfc = '${encontrado!.name} já está como presente.');
      return;
    }
    setState(() {
      _presencas[encontrado!.id] = true;
      _avisoNfc = '${encontrado.name} marcado como presente.';
    });
  }

  Future<void> _ajustarPresenca(AlunoChamada aluno) async {
    final presente = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajustar presença'),
        content: Text(aluno.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ausente'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Presente'),
          ),
        ],
      ),
    );
    if (presente != null && mounted) {
      setState(() => _presencas[aluno.id] = presente);
    }
  }

  Future<void> _pausarLeitura() async {
    setState(() {
      _scannerPausado = true;
      _lendoNfc = false;
    });
    await _nfc.parar();
  }

  Future<void> _retomarLeitura() async {
    if (!await _nfc.estaDisponivel()) {
      if (!mounted) return;
      setState(
        () => _avisoNfc =
            'NFC indisponível neste dispositivo. Ajuste a presença manualmente.',
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _scannerPausado = false;
      _avisoNfc = null;
    });
    _armarLeitura();
  }

  Future<void> _confirmarChamada() async {
    if (!_chamadaEmAndamento || _ocupado) return;
    setState(() {
      _scannerPausado = true;
      _lendoNfc = false;
    });
    await _nfc.parar();
    await _executar(() async {
      await widget.professorApi.enviarChamada(_turma.id, _presencas);
      await widget.professorApi.fecharChamada(_turma.id);
      if (!mounted) return;
      setState(() {
        _chamadaEmAndamento = false;
        _avisoNfc = null;
      });
      await _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamada registrada com sucesso.')),
      );
    });
  }

  int get _presentes => _presencas.values.where((presente) => presente).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Gestão da disciplina',
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
                Text('${_turma.week} · ${_turma.horario}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ResumoFrequencia(frequencia: _frequenciaGeral),
          const SizedBox(height: 16),
          if (_chamadaEmAndamento) ...[
            _PainelChamada(
              total: _turma.enrolledStudents.length,
              presentes: _presentes,
              ausentes: _turma.enrolledStudents.length - _presentes,
              lendoNfc: _lendoNfc,
              pausado: _scannerPausado,
              aviso: _avisoNfc,
              onPausar: _pausarLeitura,
              onRetomar: _retomarLeitura,
              onConfirmar: _confirmarChamada,
              ocupado: _ocupado,
            ),
            const SizedBox(height: 20),
          ] else
            FilledButton.icon(
              key: const Key('validar-presenca'),
              onPressed: _carregando || _ocupado ? null : _validarPresenca,
              icon: const Icon(Icons.contactless),
              label: const Text('Iniciar chamada'),
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
          if (_avisoAlunos != null)
            Text(
              _avisoAlunos!,
              key: const Key('aviso-alunos'),
              style: const TextStyle(color: Colors.red),
            ),
          if (_removidos > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _removidos == 1
                    ? '1 aluno removido, não encontrado.'
                    : '$_removidos alunos removidos, não encontrados.',
                key: const Key('aviso-alunos-removidos'),
              ),
            ),
          if (_carregando)
            const Center(child: CircularProgressIndicator())
          else if (_turma.enrolledStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nenhum aluno matriculado.')),
            )
          else
            for (final id in _turma.enrolledStudents)
              _AlunoPresencaTile(
                key: ValueKey('aluno-$id'),
                aluno: _alunos[id],
                id: id,
                presente: _presencas[id] ?? false,
                frequencia: _frequencias[id],
                chamadaEmAndamento: _chamadaEmAndamento,
                onAjustar: _alunos[id] == null
                    ? null
                    : () => _ajustarPresenca(_alunos[id]!),
                onRemover: () => _removerAluno(id),
              ),
        ],
      ),
    ),
  );
}

class _ResumoFrequencia extends StatelessWidget {
  const _ResumoFrequencia({required this.frequencia});

  final Frequencia? frequencia;

  @override
  Widget build(BuildContext context) {
    final dados = frequencia;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFD9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequência geral da turma',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dados == null
                      ? 'Sem chamadas registradas'
                      : '${dados.percentage.toStringAsFixed(0)}% de frequência geral',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelChamada extends StatelessWidget {
  const _PainelChamada({
    required this.total,
    required this.presentes,
    required this.ausentes,
    required this.lendoNfc,
    required this.pausado,
    required this.aviso,
    required this.onPausar,
    required this.onRetomar,
    required this.onConfirmar,
    required this.ocupado,
  });

  final int total;
  final int presentes;
  final int ausentes;
  final bool lendoNfc;
  final bool pausado;
  final String? aviso;
  final VoidCallback onPausar;
  final VoidCallback onRetomar;
  final VoidCallback onConfirmar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chamada · $presentes presentes · $ausentes ausentes de $total',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          lendoNfc
              ? 'Aproxime os cartões NFC dos alunos.'
              : 'Leitura pausada. Você também pode ajustar cada aluno manualmente.',
        ),
        if (aviso != null) ...[
          const SizedBox(height: 8),
          Text(aviso!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('chamada-alternar-leitura'),
              onPressed: ocupado
                  ? null
                  : pausado
                  ? onRetomar
                  : onPausar,
              icon: Icon(pausado ? Icons.contactless : Icons.pause),
              label: Text(pausado ? 'Retomar leitura' : 'Parar leitura'),
            ),
            FilledButton(
              key: const Key('chamada-confirmar'),
              onPressed: ocupado ? null : onConfirmar,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar chamada'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AlunoPresencaTile extends StatelessWidget {
  const _AlunoPresencaTile({
    super.key,
    required this.aluno,
    required this.id,
    required this.presente,
    required this.frequencia,
    required this.chamadaEmAndamento,
    required this.onAjustar,
    required this.onRemover,
  });

  final AlunoChamada? aluno;
  final String id;
  final bool presente;
  final Frequencia? frequencia;
  final bool chamadaEmAndamento;
  final VoidCallback? onAjustar;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final estudante = aluno;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(estudante?.name ?? 'Aluno $id'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('RA ${estudante?.ra ?? id}'),
            Text(presente ? 'Status: Presente' : 'Status: Ausente'),
            Text(
              'Frequência: ${frequencia == null ? '—' : '${frequencia!.percentage.toStringAsFixed(0)}%'}',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chamadaEmAndamento)
              TextButton(
                key: Key('ajustar-$id'),
                onPressed: onAjustar,
                child: const Text('Ajustar'),
              )
            else
              Icon(
                presente ? Icons.check_circle : Icons.cancel_outlined,
                color: presente ? Colors.green : Colors.black38,
              ),
            IconButton(
              tooltip: 'Remover ${aluno?.name ?? id}',
              onPressed: onRemover,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
