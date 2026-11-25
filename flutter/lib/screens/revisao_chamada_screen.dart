import 'package:flutter/material.dart';

import '../models.dart';
import '../professor_api.dart';
import '../turma.dart';
import '../turmas_api.dart' show ApiException;
import 'screens_shared.dart';

class RevisaoChamadaScreen extends StatefulWidget {
  const RevisaoChamadaScreen({
    super.key,
    required this.turma,
    required this.alunos,
    required this.presencas,
    required this.professorApi,
    this.avisoLeitura,
  });

  final Turma turma;
  final List<AlunoChamada> alunos;
  final Map<String, bool> presencas;
  final ProfessorApi professorApi;
  final String? avisoLeitura;

  @override
  State<RevisaoChamadaScreen> createState() => _RevisaoChamadaScreenState();
}

class _RevisaoChamadaScreenState extends State<RevisaoChamadaScreen> {
  late final Map<String, bool> _presencas = {
    for (final aluno in widget.alunos)
      aluno.id: widget.presencas[aluno.id] ?? false,
  };
  bool _ocupado = false;
  Map<String, bool>? _presencasSalvas;

  List<AlunoChamada> get _presentes =>
      widget.alunos.where((aluno) => _presencas[aluno.id] == true).toList();

  List<AlunoChamada> get _ausentes =>
      widget.alunos.where((aluno) => _presencas[aluno.id] != true).toList();

  bool get _presencasAtuaisSalvas {
    final salvas = _presencasSalvas;
    if (salvas == null || salvas.length != _presencas.length) return false;
    return _presencas.entries.every(
      (entry) => salvas[entry.key] == entry.value,
    );
  }

  Future<void> _ajustar(AlunoChamada aluno) async {
    final novoStatus = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IdentitasColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjustarPresenca(
        aluno: aluno,
        presente: _presencas[aluno.id] ?? false,
      ),
    );
    if (novoStatus != null && mounted) {
      setState(() => _presencas[aluno.id] = novoStatus);
    }
  }

  Future<void> _confirmar() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await widget.professorApi.abrirChamada(widget.turma.id);

      ApiException? erroPresenca;
      if (!_presencasAtuaisSalvas) {
        try {
          await widget.professorApi.enviarChamada(widget.turma.id, _presencas);
          _presencasSalvas = Map<String, bool>.of(_presencas);
        } on ApiException catch (e) {
          erroPresenca = e;
        }
      }

      ApiException? erroFechamento;
      try {
        await widget.professorApi.fecharChamada(widget.turma.id);
      } on ApiException catch (e) {
        erroFechamento = e;
      }

      if (erroPresenca != null || erroFechamento != null) {
        if (!mounted) return;
        final mensagem = erroPresenca != null && erroFechamento != null
            ? 'Não foi possível salvar a presença nem encerrar a chamada. '
                  'Presença: ${erroPresenca.message} Fechamento: ${erroFechamento.message}'
            : erroPresenca != null
            ? 'Não foi possível salvar a presença: ${erroPresenca.message}'
            : 'Presença salva, mas não foi possível encerrar a chamada: '
                  '${erroFechamento!.message}';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensagem)));
        return;
      }

      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: IdentitasColors.fundo,
    appBar: AppBar(
      backgroundColor: IdentitasColors.fundo,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text('Revisão de Chamada'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                Text(
                  '${widget.turma.name} · ${widget.turma.week}',
                  style: identitasText(
                    size: 13,
                    weight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _ResumoChamada(
                  total: widget.alunos.length,
                  presentes: _presentes.length,
                  ausentes: _ausentes.length,
                  aviso: widget.avisoLeitura,
                ),
                const SizedBox(height: 18),
                _TituloSecao('Ausentes (${_ausentes.length})'),
                for (final aluno in _ausentes)
                  _CardRegistro(
                    aluno: aluno,
                    presente: false,
                    onAjustar: () => _ajustar(aluno),
                  ),
                const SizedBox(height: 8),
                _TituloSecao('Presentes (${_presentes.length})'),
                for (final aluno in _presentes)
                  _CardRegistro(
                    aluno: aluno,
                    presente: true,
                    onAjustar: () => _ajustar(aluno),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('chamada-confirmar'),
                onPressed: _ocupado ? null : _confirmar,
                style: FilledButton.styleFrom(
                  backgroundColor: IdentitasColors.amarelo,
                  foregroundColor: IdentitasColors.preto,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _ocupado
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Confirmar chamada', style: identitasText(size: 15)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResumoChamada extends StatelessWidget {
  const _ResumoChamada({
    required this.total,
    required this.presentes,
    required this.ausentes,
    required this.aviso,
  });

  final int total;
  final int presentes;
  final int ausentes;
  final String? aviso;

  Widget _item(int valor, String texto) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$valor', style: identitasText(size: 23, weight: FontWeight.bold)),
        Text(texto, style: identitasText(size: 10)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: IdentitasColors.amarelo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leitura NFC encerrada',
          style: identitasText(size: 17, weight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          aviso ?? 'Confira os registros antes de confirmar',
          style: identitasText(size: 10),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _item(total, 'Alunos'),
            _item(presentes, 'Presentes'),
            _item(ausentes, 'Ausentes'),
          ],
        ),
      ],
    ),
  );
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texto,
      style: identitasText(
        size: 16,
        weight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

class _CardRegistro extends StatelessWidget {
  const _CardRegistro({
    required this.aluno,
    required this.presente,
    required this.onAjustar,
  });

  final AlunoChamada aluno;
  final bool presente;
  final VoidCallback onAjustar;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: IdentitasColors.creme,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          aluno.name,
          style: identitasText(size: 14, weight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'RA ${aluno.ra}',
          style: identitasText(
            size: 10,
            weight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: presente ? IdentitasColors.amarelo : null,
                border: presente
                    ? null
                    : Border.all(color: IdentitasColors.preto),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                presente ? 'Presente' : 'Ausente',
                style: identitasText(size: 11),
              ),
            ),
            TextButton(
              key: Key('ajustar-${aluno.id}'),
              onPressed: onAjustar,
              style: TextButton.styleFrom(
                foregroundColor: IdentitasColors.preto,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ajustar',
                style: identitasText(
                  size: 11,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AjustarPresenca extends StatefulWidget {
  const _AjustarPresenca({required this.aluno, required this.presente});

  final AlunoChamada aluno;
  final bool presente;

  @override
  State<_AjustarPresenca> createState() => _AjustarPresencaState();
}

class _AjustarPresencaState extends State<_AjustarPresenca> {
  late bool _presente = widget.presente;

  Widget _opcao(String texto, bool valor) {
    final selecionado = _presente == valor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selecionado ? IdentitasColors.amarelo : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: IdentitasColors.preto),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _presente = valor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selecionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(texto, style: identitasText(size: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajustar presença',
            style: identitasText(size: 20, weight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.aluno.name,
            style: identitasText(size: 16, weight: FontWeight.w600),
          ),
          Text(
            'RA ${widget.aluno.ra}',
            style: identitasText(size: 10, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Text('Selecione o registro correto', style: identitasText(size: 13)),
          const SizedBox(height: 8),
          _opcao('Presente', true),
          _opcao('Ausente', false),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              key: const Key('salvar-ajuste-presenca'),
              onPressed: () => Navigator.pop(context, _presente),
              style: FilledButton.styleFrom(
                backgroundColor: IdentitasColors.amarelo,
                foregroundColor: IdentitasColors.preto,
              ),
              child: Text('Salvar alteração', style: identitasText(size: 13)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: IdentitasColors.preto,
                side: const BorderSide(color: IdentitasColors.preto),
              ),
              child: Text('Cancelar', style: identitasText(size: 13)),
            ),
          ),
        ],
      ),
    ),
  );
}
