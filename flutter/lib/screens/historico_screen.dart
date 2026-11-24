import 'package:flutter/material.dart';

import 'screens_shared.dart';

enum TipoRegistro { nfc, manual, falta }

class Registro {
  const Registro(
    this.data,
    this.disciplina,
    this.professor,
    this.tipo,
  );

  final DateTime data;
  final String disciplina;
  final String professor;
  final TipoRegistro tipo;
}

final _registros = [
  Registro(
    DateTime(2026, 10, 6, 20, 50),
    'Banco de Dados',
    'Profa. Mariana Costa',
    TipoRegistro.nfc,
  ),
  Registro(
    DateTime(2026, 10, 6, 19, 10),
    'Projeto Integrador VI',
    'Prof. Rafael Almeida',
    TipoRegistro.manual,
  ),
  Registro(
    DateTime(2026, 10, 5, 19, 10),
    'Engenharia de Software',
    'Profa. Camila Rodrigues',
    TipoRegistro.falta,
  ),
  Registro(
    DateTime(2026, 10, 2, 20, 50),
    'Redes de Computadores',
    'Prof. Lucas Ferreira',
    TipoRegistro.nfc,
  ),
];

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String _periodo = 'Últimos 7 dias';
  String? _disciplina;

  static const _periodos = {
    'Últimos 7 dias': 7,
    'Últimos 30 dias': 30,
    'Todo o semestre': null,
  };

  @override
  Widget build(BuildContext context) {
    final dias = _periodos[_periodo];
    final referencia = _registros
        .map((registro) => registro.data)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final filtrados = _registros
        .where(
          (registro) =>
              dias == null ||
              referencia.difference(registro.data).inDays < dias,
        )
        .where(
          (registro) =>
              _disciplina == null || registro.disciplina == _disciplina,
        )
        .toList();
    final disciplinas = {
      for (final registro in _registros) registro.disciplina,
    }.toList();

    final itens = <Widget>[];
    String? diaAtual;
    for (final registro in filtrados) {
      final dia =
          '${registro.data.day.toString().padLeft(2, '0')} '
          '${_meses[registro.data.month - 1]} ${registro.data.year}';
      if (dia != diaAtual) {
        diaAtual = dia;
        itens.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              dia,
              style: identitasText(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ),
        );
      }
      itens.add(_CardRegistro(registro));
    }

    return Scaffold(
      backgroundColor: IdentitasColors.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text(
              'Histórico',
              style: identitasText(
                size: 26,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Suas presenças e validações',
              style: identitasText(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Filtro<String>(
                    valor: _periodo,
                    cor: IdentitasColors.amarelo,
                    opcoes: {
                      for (final periodo in _periodos.keys) periodo: periodo,
                    },
                    onChanged: (value) {
                      if (value != null) setState(() => _periodo = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Filtro<String?>(
                    valor: _disciplina,
                    cor: IdentitasColors.creme,
                    opcoes: {
                      null: 'Todas as disciplinas',
                      for (final disciplina in disciplinas)
                        disciplina: disciplina,
                    },
                    onChanged: (value) => setState(() => _disciplina = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (itens.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'Nenhum registro no período',
                  textAlign: TextAlign.center,
                  style: identitasText(
                    size: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ...itens,
          ],
        ),
      ),
    );
  }
}

const _meses = [
  'jan.',
  'fev.',
  'mar.',
  'abr.',
  'mai.',
  'jun.',
  'jul.',
  'ago.',
  'set.',
  'out.',
  'nov.',
  'dez.',
];

class _Filtro<T> extends StatelessWidget {
  const _Filtro({
    required this.valor,
    required this.cor,
    required this.opcoes,
    required this.onChanged,
  });

  final T valor;
  final Color cor;
  final Map<T, String> opcoes;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          dropdownColor: cor,
          iconEnabledColor: IdentitasColors.preto,
          style: identitasText(size: 12),
          items: [
            for (final entry in opcoes.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
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
      TipoRegistro.nfc => (
          'Presença via NFC',
          Icons.check_circle_outline,
          true,
        ),
      TipoRegistro.manual => (
          'Presença Manual',
          Icons.warning_amber_outlined,
          false,
        ),
      TipoRegistro.falta => ('Falta', Icons.cancel_outlined, false),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IdentitasColors.creme,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${registro.data.hour.toString().padLeft(2, '0')}:'
            '${registro.data.minute.toString().padLeft(2, '0')}',
            style: identitasText(size: 10, weight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            registro.disciplina,
            style: identitasText(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            registro.professor,
            style: identitasText(
              size: 10,
              weight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: preenchido ? IdentitasColors.amarelo : null,
              border: preenchido
                  ? null
                  : Border.all(color: IdentitasColors.preto),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 15, color: IdentitasColors.preto),
                const SizedBox(width: 6),
                Text(texto, style: identitasText(size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
