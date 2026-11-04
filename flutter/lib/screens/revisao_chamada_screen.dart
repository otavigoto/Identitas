import 'package:flutter/material.dart';

import '../theme.dart';
import 'gestao_disciplina_screen.dart';

class RevisaoChamadaScreen extends StatefulWidget {
  const RevisaoChamadaScreen({super.key});

  @override
  State<RevisaoChamadaScreen> createState() => _RevisaoChamadaScreenState();
}

class _RevisaoChamadaScreenState extends State<RevisaoChamadaScreen> {
  // RA -> presente. ponytail: leitura NFC simulada; virá da sessão de chamada no backend.
  final _presenca = {for (final a in alunosTurma) a.ra: !{'24010001', '24010002'}.contains(a.ra)};

  Future<void> _ajustar(AlunoFrequencia aluno) async {
    final novo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AjustarPresenca(aluno: aluno, presente: _presenca[aluno.ra]!),
    );
    if (novo != null) setState(() => _presenca[aluno.ra] = novo);
  }

  @override
  Widget build(BuildContext context) {
    final ausentes = alunosTurma.where((a) => !_presenca[a.ra]!).toList();
    final presentes = alunosTurma.where((a) => _presenca[a.ra]!).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                children: [
                  Text('Revisão de Chamada', style: urbanist(size: 26, weight: FontWeight.bold, color: AppColors.branco)),
                  const SizedBox(height: 4),
                  Text('Turma 101 · 6o semestre', style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.white70)),
                  const SizedBox(height: 24),
                  _CardResumo(total: alunosTurma.length, presentes: presentes.length, ausentes: ausentes.length),
                  const SizedBox(height: 20),
                  _Secao('Ausentes (${ausentes.length})'),
                  for (final a in ausentes) _CardRegistro(a, presente: false, onAjustar: () => _ajustar(a)),
                  const SizedBox(height: 8),
                  _Secao('Presentes (${presentes.length})'),
                  for (final a in presentes) _CardRegistro(a, presente: true, onAjustar: () => _ajustar(a)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _BotaoAmarelo(
                'Confirmar chamada',
                // ponytail: só feedback visual até existir o endpoint de confirmação.
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Chamada confirmada'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardResumo extends StatelessWidget {
  const _CardResumo({required this.total, required this.presentes, required this.ausentes});

  final int total, presentes, ausentes;

  @override
  Widget build(BuildContext context) {
    Widget numero(int valor, String rotulo) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$valor', style: urbanist(size: 24, weight: FontWeight.bold)),
              Text(rotulo, style: urbanist(size: 11)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.amarelo, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leitura NFC encerrada', style: urbanist(size: 18, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Confira os registros antes de confirmar', style: urbanist(size: 11)),
          const SizedBox(height: 12),
          Row(children: [numero(total, 'Alunos'), numero(presentes, 'Presentes'), numero(ausentes, 'Ausentes')]),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(titulo, style: urbanist(size: 16, weight: FontWeight.w600, color: AppColors.branco)),
      );
}

class _CardRegistro extends StatelessWidget {
  const _CardRegistro(this.aluno, {required this.presente, required this.onAjustar});

  final AlunoFrequencia aluno;
  final bool presente;
  final VoidCallback onAjustar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: AppColors.creme, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(aluno.nome, style: urbanist(size: 14), overflow: TextOverflow.ellipsis),
          Text('RA ${aluno.ra}', style: urbanist(size: 10, weight: FontWeight.w400, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: presente ? AppColors.amarelo : null,
                  border: presente ? null : Border.all(color: AppColors.preto),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(presente ? 'Presente' : 'Ausente', style: urbanist(size: 11)),
              ),
              GestureDetector(
                onTap: onAjustar,
                child: Text('Ajustar', style: urbanist(size: 11).copyWith(decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AjustarPresenca extends StatefulWidget {
  const _AjustarPresenca({required this.aluno, required this.presente});

  final AlunoFrequencia aluno;
  final bool presente;

  @override
  State<_AjustarPresenca> createState() => _AjustarPresencaState();
}

class _AjustarPresencaState extends State<_AjustarPresenca> {
  late bool _presente = widget.presente;

  @override
  Widget build(BuildContext context) {
    Widget opcao(String texto, bool valor) {
      final selecionado = _presente == valor;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selecionado ? AppColors.amarelo : Colors.transparent,
          shape: RoundedRectangleBorder(side: const BorderSide(), borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _presente = valor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(selecionado ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: AppColors.preto),
                  const SizedBox(width: 10),
                  Text(texto, style: urbanist(size: 14)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajustar presença', style: urbanist(size: 20, weight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.aluno.nome, style: urbanist(size: 16, weight: FontWeight.w600)),
            Text('RA ${widget.aluno.ra}', style: urbanist(size: 10, weight: FontWeight.w400, color: Colors.black54)),
            const SizedBox(height: 16),
            Text('Selecione o registro correto', style: urbanist(size: 13)),
            const SizedBox(height: 8),
            opcao('Presente', true),
            opcao('Ausente', false),
            const SizedBox(height: 6),
            _BotaoAmarelo('Salvar alteração', onPressed: () => Navigator.pop(context, _presente)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.preto),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: urbanist(size: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoAmarelo extends StatelessWidget {
  const _BotaoAmarelo(this.texto, {required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amarelo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(texto, style: urbanist(size: 15)),
      ),
    );
  }
}
