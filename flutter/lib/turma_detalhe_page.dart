import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'professor_api.dart';
import 'screens/revisao_chamada_screen.dart';
import 'services/nfc_service.dart';
import 'turma.dart';
import 'turmas_api.dart';

class TurmaDetalhePage extends StatefulWidget {
  const TurmaDetalhePage({
    super.key,
    required this.api,
    required this.professorApi,
    required this.turma,
    required this.onChanged,
    this.nfcService,
  });

  final TurmasApi api;
  final ProfessorApi professorApi;
  final Turma turma;
  final ValueChanged<Turma> onChanged;
  final NfcService? nfcService;

  @override
  State<TurmaDetalhePage> createState() => _TurmaDetalhePageState();
}

class _TurmaDetalhePageState extends State<TurmaDetalhePage> {
  late Turma _turma = widget.turma;
  late final NfcService _nfc = widget.nfcService ?? NfcService();
  final _busca = TextEditingController();

  Map<String, AlunoChamada> _alunos = {};
  Map<String, bool> _presencas = {};
  Map<String, Frequencia> _frequencias = {};
  Frequencia? _frequenciaGeral;
  bool _carregando = true;
  bool _ocupado = false;
  bool _chamadaAtiva = false;
  bool _lendoNfc = false;
  bool _scannerPausado = false;
  String? _erro;
  String? _avisoNfc;

  @override
  void initState() {
    super.initState();
    _busca.addListener(_atualizarBusca);
    _carregar();
  }

  @override
  void dispose() {
    _busca
      ..removeListener(_atualizarBusca)
      ..dispose();
    unawaited(_nfc.parar());
    super.dispose();
  }

  void _atualizarBusca() => setState(() {});

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await widget.professorApi.listaChamada(_turma.id);
      final resumo = await widget.professorApi.resumoFrequencia(_turma.id);
      if (!mounted) return;

      final attendance = resumo['attendance'];
      final alunosResumo = resumo['students'] as List<dynamic>? ?? const [];
      setState(() {
        _alunos = {for (final aluno in lista.alunos) aluno.id: aluno};
        _presencas = {
          for (final aluno in lista.alunos) aluno.id: aluno.present,
        };
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
        _erro = null;
      });

      if (lista.ausentes.isNotEmpty) {
        var turmaAtualizada = _turma;
        for (final id in lista.ausentes) {
          turmaAtualizada = await widget.api.removerAluno(_turma.id, id);
        }
        if (!mounted) return;
        setState(() => _turma = turmaAtualizada);
        widget.onChanged(turmaAtualizada);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<AlunoChamada> get _alunosFiltrados {
    final termo = _busca.text.trim().toLowerCase();
    final alunos = _alunos.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (termo.isEmpty) return alunos;
    return alunos
        .where(
          (aluno) =>
              aluno.name.toLowerCase().contains(termo) ||
              aluno.ra.toLowerCase().contains(termo),
        )
        .toList();
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _iniciarChamada() async {
    if (_ocupado || _alunos.isEmpty) {
      if (_alunos.isEmpty) _mostrarErro('Esta disciplina não tem alunos.');
      return;
    }
    setState(() => _ocupado = true);
    try {
      await widget.professorApi.abrirChamada(_turma.id);
      if (!mounted) return;
      setState(() {
        _chamadaAtiva = true;
        _scannerPausado = false;
        _avisoNfc = null;
      });
      if (!await _nfc.estaDisponivel()) {
        if (!mounted) return;
        setState(() {
          _scannerPausado = true;
          _avisoNfc = 'NFC indisponível. Você pode ajustar a chamada manualmente.';
        });
        return;
      }
      _armarLeitura();
    } on ApiException catch (e) {
      _mostrarErro(e.message);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _armarLeitura() {
    if (!mounted || !_chamadaAtiva || _scannerPausado || _lendoNfc) return;
    setState(() => _lendoNfc = true);
    unawaited(
      _nfc
          .lerCartao(
            onTagLida: (tag) {
              if (!mounted || !_chamadaAtiva) return;
              setState(() => _lendoNfc = false);
              final uid = NfcService.uidDoTag(tag);
              if (uid == null) {
                setState(
                  () => _avisoNfc = 'Não foi possível identificar o cartão.',
                );
              } else {
                _marcarCartao(uid);
              }
              Future<void>.delayed(const Duration(milliseconds: 350), () {
                if (mounted) _armarLeitura();
              });
            },
            onErro: () {
              if (!mounted || !_chamadaAtiva) return;
              setState(() {
                _lendoNfc = false;
                _scannerPausado = true;
                _avisoNfc = 'Falha ao ler NFC. Tente retomar a leitura.';
              });
            },
          )
          .catchError((Object error) {
            if (!mounted || !_chamadaAtiva) return;
            setState(() {
              _lendoNfc = false;
              _scannerPausado = true;
              _avisoNfc = 'Falha ao iniciar a leitura NFC: $error';
            });
          }),
    );
  }

  void _marcarCartao(String uid) {
    final normalizado = uid.trim().replaceAll(':', '').toUpperCase();
    AlunoChamada? alunoEncontrado;
    for (final aluno in _alunos.values) {
      if (aluno.nfcUid?.trim().replaceAll(':', '').toUpperCase() ==
          normalizado) {
        alunoEncontrado = aluno;
        break;
      }
    }
    if (alunoEncontrado == null) {
      setState(() => _avisoNfc = 'Cartão não vinculado a aluno desta disciplina.');
      return;
    }
    if (_presencas[alunoEncontrado.id] == true) {
      setState(() => _avisoNfc = '${alunoEncontrado!.name} já está presente.');
      return;
    }
    setState(() {
      _presencas[alunoEncontrado!.id] = true;
      _avisoNfc = '${alunoEncontrado.name} marcado como presente.';
    });
  }

  Future<void> _revisarChamada() async {
    if (!_chamadaAtiva || _ocupado) return;
    setState(() {
      _ocupado = true;
      _scannerPausado = true;
      _lendoNfc = false;
    });
    await _nfc.parar();
    if (!mounted) return;
    setState(() => _ocupado = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RevisaoChamadaScreen(
          turma: _turma,
          alunos: _alunos.values.toList(),
          presencas: _presencas,
          professorApi: widget.professorApi,
          avisoLeitura: _avisoNfc,
        ),
      ),
    );
    if (resultado == true && mounted) {
      setState(() {
        _chamadaAtiva = false;
        _avisoNfc = null;
      });
      await _carregar();
    }
  }

  Future<void> _retomarLeitura() async {
    if (!await _nfc.estaDisponivel()) {
      if (mounted) {
        setState(
          () => _avisoNfc =
              'NFC indisponível. Você pode revisar a chamada manualmente.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _scannerPausado = false;
      _avisoNfc = null;
    });
    _armarLeitura();
  }

  int get _presentes => _presencas.values.where((presente) => presente).length;

  @override
  Widget build(BuildContext context) {
    final frequencia = _frequenciaGeral?.percentage ?? 0;
    final alunos = _alunosFiltrados;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Gestão da Disciplina'),
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF9FF2E)),
              )
            : _erro != null
            ? _ErroDisciplina(mensagem: _erro!, onTentar: _carregar)
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        Text(
                          '${_turma.name} · ${_turma.week} · ${_turma.horario}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _CartaoFrequencia(
                          percentual: frequencia,
                          matriculados: _alunos.length,
                        ),
                        if (_chamadaAtiva) ...[
                          const SizedBox(height: 12),
                          _StatusChamada(
                            lendoNfc: _lendoNfc,
                            presentes: _presentes,
                            ausentes: _alunos.length - _presentes,
                            aviso: _avisoNfc,
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Alunos matriculados',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _alunos.length.toString().padLeft(2, '0'),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('buscar-aluno-chamada'),
                          controller: _busca,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nome ou RA',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFFEFFD9),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (alunos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              'Nenhum aluno encontrado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          for (final aluno in alunos)
                            _FrequenciaAluno(
                              aluno: aluno,
                              frequencia: _frequencias[aluno.id]?.percentage,
                            ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _BotaoChamada(
                      ocupado: _ocupado,
                      chamadaAtiva: _chamadaAtiva,
                      leituraAtiva: _lendoNfc,
                      onIniciar: _iniciarChamada,
                      onRevisar: _revisarChamada,
                      onRetomar: _retomarLeitura,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CartaoFrequencia extends StatelessWidget {
  const _CartaoFrequencia({
    required this.percentual,
    required this.matriculados,
  });

  final double percentual;
  final int matriculados;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FF2E),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequência geral'),
        const SizedBox(height: 2),
        Text(
          '${percentual.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 42,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Acumulada no semestre', style: TextStyle(fontSize: 11)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percentual / 100).clamp(0, 1),
            minHeight: 5,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$matriculados ${matriculados == 1 ? 'aluno matriculado' : 'alunos matriculados'}',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}

class _StatusChamada extends StatelessWidget {
  const _StatusChamada({
    required this.lendoNfc,
    required this.presentes,
    required this.ausentes,
    required this.aviso,
  });

  final bool lendoNfc;
  final int presentes;
  final int ausentes;
  final String? aviso;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEFFD9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lendoNfc ? 'Aproxime os cartões NFC' : 'Leitura pausada',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$presentes presentes · $ausentes ausentes'),
        if (aviso != null)
          Text(aviso!, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

class _FrequenciaAluno extends StatelessWidget {
  const _FrequenciaAluno({required this.aluno, required this.frequencia});

  final AlunoChamada aluno;
  final double? frequencia;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEFFD9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aluno.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'RA ${aluno.ra}',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
        Text(
          '${(frequencia ?? 0).toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _BotaoChamada extends StatelessWidget {
  const _BotaoChamada({
    required this.ocupado,
    required this.chamadaAtiva,
    required this.leituraAtiva,
    required this.onIniciar,
    required this.onRevisar,
    required this.onRetomar,
  });

  final bool ocupado;
  final bool chamadaAtiva;
  final bool leituraAtiva;
  final VoidCallback onIniciar;
  final VoidCallback onRevisar;
  final VoidCallback onRetomar;

  Widget _botao(String label, VoidCallback action, {Key? key}) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      key: key,
      onPressed: ocupado ? null : action,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF9FF2E),
        foregroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!chamadaAtiva) {
      return _botao(
        'Iniciar chamada',
        onIniciar,
        key: const Key('validar-presenca'),
      );
    }
    if (leituraAtiva) {
      return _botao(
        'Encerrar leitura e revisar',
        onRevisar,
        key: const Key('chamada-finalizar-leitura'),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botao(
          'Retomar leitura NFC',
          onRetomar,
          key: const Key('chamada-retomar-leitura'),
        ),
        TextButton(
          key: const Key('chamada-ver-revisao'),
          onPressed: ocupado ? null : onRevisar,
          child: const Text(
            'Revisar chamada manualmente',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ErroDisciplina extends StatelessWidget {
  const _ErroDisciplina({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onTentar, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}
