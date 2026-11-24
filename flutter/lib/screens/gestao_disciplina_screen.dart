import 'package:flutter/material.dart';

import 'screens_shared.dart';

class AlunoFrequencia {
  const AlunoFrequencia(this.nome, this.ra, this.frequencia);

  final String nome;
  final String ra;
  final int frequencia;
}

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
    final filtrados = alunosTurma
        .where(
          (aluno) =>
              aluno.nome.toLowerCase().contains(termo) ||
              aluno.ra.contains(termo),
        )
        .toList();

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
              'Gestão da Disciplina',
              style: identitasText(
                size: 26,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Turma 101 · 6º semestre',
              style: identitasText(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const _CardFrequencia(frequencia: 85, matriculados: 8),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alunos matriculados',
                    style: identitasText(
                      size: 18,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  alunosTurma.length.toString().padLeft(2, '0'),
                  style: identitasText(
                    size: 12,
                    weight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _busca = value),
              style: identitasText(size: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou RA',
                hintStyle: identitasText(
                  size: 15,
                  weight: FontWeight.w400,
                  color: Colors.black54,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: IdentitasColors.preto,
                ),
                filled: true,
                fillColor: IdentitasColors.creme,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final aluno in filtrados) _CardAluno(aluno),
          ],
        ),
      ),
    );
  }
}

class _CardFrequencia extends StatelessWidget {
  const _CardFrequencia({
    required this.frequencia,
    required this.matriculados,
  });

  final int frequencia;
  final int matriculados;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IdentitasColors.amarelo,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequência geral',
            style: identitasText(size: 16, weight: FontWeight.w500),
          ),
          Text(
            '$frequencia%',
            style: identitasText(
              size: 64,
              weight: FontWeight.bold,
              color: IdentitasColors.fundo,
            ),
          ),
          Text(
            'Acumulada no semestre',
            style: identitasText(size: 13),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frequencia / 100,
              minHeight: 6,
              color: IdentitasColors.fundo,
              backgroundColor: IdentitasColors.fundo.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$matriculados alunos matriculados',
            style: identitasText(size: 15),
          ),
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
      decoration: BoxDecoration(
        color: IdentitasColors.creme,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: identitasText(size: 16, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'RA ${aluno.ra}',
                  style: identitasText(
                    size: 11,
                    weight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${aluno.frequencia}%',
            style: identitasText(size: 20, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
