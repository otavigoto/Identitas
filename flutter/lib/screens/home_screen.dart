import 'package:flutter/material.dart';

import '../theme.dart';

enum StatusAula { presente, proxima, agendado }

class Aula {
  final String horario, nome, sala;
  final StatusAula status;
  const Aula(this.horario, this.nome, this.sala, this.status);
}

// ponytail: dados fixos do Figma; trocar pela API quando o backend expor as aulas do dia.
const _aulasHoje = [
  Aula('08:00 - 09:40', 'Cálculo Diferencial', 'Lab 03 - H15', StatusAula.presente),
  Aula('10:00 - 11:40', 'Engenharia de Software', 'Sala 204 - H15', StatusAula.proxima),
  Aula('11:40 - 12:30', 'Projeto Integrador', 'Sala A06 - H15', StatusAula.agendado),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.nome = 'Odete Roitmann'});

  final String nome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _BotaoNfc(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(31, 16, 31, 100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Olá,\n$nome',
                      style: const TextStyle(color: AppColors.branco, fontSize: 20, fontWeight: FontWeight.bold, height: 1)),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(color: AppColors.amarelo, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, size: 34, color: AppColors.preto),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Identitas', style: TextStyle(color: AppColors.branco, fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Próxima Aula', style: TextStyle(color: AppColors.branco, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const _CardProximaAula(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text('Resumo de Hoje',
                      style: TextStyle(color: AppColors.branco, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('ver todas', style: TextStyle(color: AppColors.branco, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final aula in _aulasHoje) _CardAula(aula),
          ],
        ),
      ),
    );
  }
}

class _CardProximaAula extends StatelessWidget {
  const _CardProximaAula();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(color: AppColors.amarelo, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.preto, borderRadius: BorderRadius.circular(20)),
            child: const Text('HOJE • 10:00 - 11:40',
                style: TextStyle(color: AppColors.amarelo, fontSize: 14, fontWeight: FontWeight.w200)),
          ),
          const SizedBox(height: 12),
          Text('Engenharia de\nSoftware', style: urbanist(size: 32, weight: FontWeight.bold).copyWith(height: 1)),
          const SizedBox(height: 16),
          _InfoLinha(Icons.person_outline, 'Prof. Dr. Ricardo Almeida'),
          const SizedBox(height: 8),
          _InfoLinha(Icons.location_on_outlined, 'Sala 204 - H15'),
        ],
      ),
    );
  }
}

class _CardAula extends StatelessWidget {
  const _CardAula(this.aula);

  final Aula aula;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(color: AppColors.creme, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(aula.horario,
                    style: const TextStyle(color: AppColors.preto, fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              _Selo(aula.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(aula.nome, style: const TextStyle(color: AppColors.preto, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _InfoLinha(Icons.location_on_outlined, aula.sala),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.status);

  final StatusAula status;

  @override
  Widget build(BuildContext context) {
    final (texto, fundo, ponto) = switch (status) {
      StatusAula.presente => ('PRESENTE', const Color(0xFFB6F7A1), const Color(0xFF22C70B)),
      StatusAula.proxima => ('PRÓXIMA', const Color(0xFFFFD3A3), const Color(0xFFFF7A00)),
      StatusAula.agendado => ('AGENDADO', const Color(0xFFC9C9B8), const Color(0xFF5E5E5E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: ponto),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(color: AppColors.preto, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  const _InfoLinha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: AppColors.preto),
        const SizedBox(width: 8),
        Flexible(child: Text(texto, style: urbanist(), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _BotaoNfc extends StatelessWidget {
  const _BotaoNfc();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        backgroundColor: AppColors.preto,
        shape: const CircleBorder(),
        // ponytail: sem ação até a tela de NFC (do Nicolas) existir.
        onPressed: () {},
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi, color: AppColors.amarelo, size: 26),
            Text('NFC', style: TextStyle(color: AppColors.amarelo, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
