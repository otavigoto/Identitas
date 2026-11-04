import 'package:flutter/material.dart';

import '../theme.dart';

enum TipoRegistro { nfc, manual, falta }

class Registro {
  final DateTime data;
  final String disciplina, professor;
  final TipoRegistro tipo;
  const Registro(this.data, this.disciplina, this.professor, this.tipo);
}

// ponytail: dados fixos (os 4 primeiros vêm do Figma); trocar pelo histórico do aluno na API.
final _registros = [
  Registro(DateTime(2026, 10, 6, 20, 50), 'Banco de Dados', 'Profa. Mariana Costa', TipoRegistro.nfc),
  Registro(DateTime(2026, 10, 6, 19, 10), 'Projeto Integrador VI', 'Prof. Rafael Almeida', TipoRegistro.manual),
  Registro(DateTime(2026, 10, 5, 19, 10), 'Engenharia de Software', 'Profa. Camila Rodrigues', TipoRegistro.falta),
  Registro(DateTime(2026, 10, 2, 20, 50), 'Redes de Computadores', 'Prof. Lucas Ferreira', TipoRegistro.nfc),
  Registro(DateTime(2026, 9, 22, 19, 10), 'Banco de Dados', 'Profa. Mariana Costa', TipoRegistro.nfc),
];

const _periodos = {'Últimos 7 dias': 7, 'Últimos 30 dias': 30, 'Todo o semestre': null};
const _meses = ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'];

String _formatarDia(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]} ${d.year}';
String _formatarHora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String _periodo = _periodos.keys.first;
  String? _disciplina;

  @override
  Widget build(BuildContext context) {
    final dias = _periodos[_periodo];
    // ponytail: período conta a partir do registro mais recente (dados fixos); usar DateTime.now() com a API.
    final referencia = _registros.map((r) => r.data).reduce((a, b) => a.isAfter(b) ? a : b);
    final filtrados = _registros
        .where((r) => dias == null || referencia.difference(r.data).inDays < dias)
        .where((r) => _disciplina == null || r.disciplina == _disciplina)
        .toList();
    final disciplinas = {for (final r in _registros) r.disciplina}.toList()..sort();

    final itens = <Widget>[];
    String? diaAtual;
    for (final r in filtrados) {
      final dia = _formatarDia(r.data);
      if (dia != diaAtual) {
        diaAtual = dia;
        itens.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(dia, style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.white70)),
        ));
      }
      itens.add(_CardRegistro(r));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          children: [
            Text('Histórico', style: urbanist(size: 26, weight: FontWeight.bold, color: AppColors.branco)),
            const SizedBox(height: 4),
            Text('Suas presenças e validações', style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.white70)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Filtro<String>(
                    valor: _periodo,
                    cor: AppColors.amarelo,
                    opcoes: {for (final p in _periodos.keys) p: p},
                    onChanged: (v) => setState(() => _periodo = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Filtro<String?>(
                    valor: _disciplina,
                    cor: AppColors.creme,
                    opcoes: {null: 'Filtrar por disciplina', for (final d in disciplinas) d: d},
                    onChanged: (v) => setState(() => _disciplina = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (itens.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('Nenhum registro no período',
                    textAlign: TextAlign.center, style: urbanist(size: 14, color: Colors.white70)),
              ),
            ...itens,
          ],
        ),
      ),
    );
  }
}

class _Filtro<T> extends StatelessWidget {
  const _Filtro({required this.valor, required this.cor, required this.opcoes, required this.onChanged});

  final T valor;
  final Color cor;
  final Map<T, String> opcoes;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          dropdownColor: cor,
          iconEnabledColor: AppColors.preto,
          style: urbanist(size: 12),
          items: [
            for (final e in opcoes.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CardRegistro extends StatelessWidget {
  const _CardRegistro(this.registro);

  final Registro registro;

  @override
  Widget build(BuildContext context) {
    final (texto, icone, preenchido) = switch (registro.tipo) {
      TipoRegistro.nfc => ('Presença via NFC', Icons.check_circle_outline, true),
      TipoRegistro.manual => ('Presença Manual', Icons.warning_amber_outlined, false),
      TipoRegistro.falta => ('Falta', Icons.cancel_outlined, false),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.creme, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatarHora(registro.data), style: urbanist(size: 10, weight: FontWeight.w400)),
          const SizedBox(height: 4),
          Text(registro.disciplina, style: urbanist(size: 14)),
          const SizedBox(height: 4),
          Text(registro.professor, style: urbanist(size: 10, weight: FontWeight.w400, color: Colors.black54)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: preenchido ? AppColors.amarelo : null,
              border: preenchido ? null : Border.all(color: AppColors.preto),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 15, color: AppColors.preto),
                const SizedBox(width: 6),
                Text(texto, style: urbanist(size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
