import 'package:flutter/material.dart';

import '../theme.dart';

class AlunoFrequencia {
  final String nome, ra;
  final int frequencia;
  const AlunoFrequencia(this.nome, this.ra, this.frequencia);
}

// ponytail: dados fixos (os 5 primeiros vêm do Figma); trocar pela API da turma.
const alunosTurma = [
  AlunoFrequencia('Ana Beatriz Lima', '24010001', 70),
  AlunoFrequencia('Bruno Henrique Santos', '24010002', 75),
  AlunoFrequencia('Camila Oliveira', '24010003', 80),
  AlunoFrequencia('Daniel Ferreira', '24010004', 85),
  AlunoFrequencia('Eduarda Martins', '24010005', 90),
  AlunoFrequencia('Felipe Souza', '24010006', 92),
  AlunoFrequencia('Gabriela Rocha', '24010007', 95),
  AlunoFrequencia('Henrique Alves', '24010008', 98),
];

class GestaoDisciplinaScreen extends StatefulWidget {
  const GestaoDisciplinaScreen({super.key});

  @override
  State<GestaoDisciplinaScreen> createState() => _GestaoDisciplinaScreenState();
}

class _GestaoDisciplinaScreenState extends State<GestaoDisciplinaScreen> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _busca.toLowerCase();
    final filtrados = alunosTurma.where((a) => a.nome.toLowerCase().contains(termo) || a.ra.contains(termo)).toList();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.preto, Color(0xFF666666)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            children: [
              Text('Gestão da Disciplina', style: urbanist(size: 26, weight: FontWeight.bold, color: AppColors.branco)),
              const SizedBox(height: 4),
              Text('Turma 101 · 6o semestre', style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.white70)),
              const SizedBox(height: 24),
              const _CardFrequencia(frequencia: 85, matriculados: 8),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Alunos matriculados',
                        style: urbanist(size: 18, weight: FontWeight.w600, color: AppColors.branco)),
                  ),
                  Text(alunosTurma.length.toString().padLeft(2, '0'),
                      style: urbanist(size: 12, weight: FontWeight.w400, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _busca = v),
                style: urbanist(size: 15),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou RA',
                  hintStyle: urbanist(size: 15, weight: FontWeight.w400, color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: AppColors.preto),
                  filled: true,
                  fillColor: AppColors.creme,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              for (final aluno in filtrados) _CardAluno(aluno),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFrequencia extends StatelessWidget {
  const _CardFrequencia({required this.frequencia, required this.matriculados});

  final int frequencia, matriculados;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.amarelo, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frequência geral', style: urbanist(size: 14)),
          Text('$frequencia%', style: urbanist(size: 64, weight: FontWeight.bold, color: AppColors.fundo)),
          Text('Acumulada no semestre', style: urbanist(size: 12)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frequencia / 100,
              minHeight: 6,
              color: AppColors.fundo,
              backgroundColor: AppColors.fundo.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(height: 10),
          Text('$matriculados alunos matriculados', style: urbanist(size: 15)),
        ],
      ),
    );
  }
}

class _CardAluno extends StatelessWidget {
  const _CardAluno(this.aluno);

  final AlunoFrequencia aluno;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: AppColors.creme, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aluno.nome, style: urbanist(size: 16), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('RA ${aluno.ra}', style: urbanist(size: 11, weight: FontWeight.w400, color: Colors.black54)),
              ],
            ),
          ),
          Text('${aluno.frequencia}%', style: urbanist(size: 20, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}
