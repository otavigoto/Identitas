import 'package:flutter/material.dart';

import '../theme.dart';

class CarteirinhaScreen extends StatelessWidget {
  // ponytail: dados fixos do Figma (Perfil / Aluno); trocar pelo usuário logado.
  const CarteirinhaScreen({
    super.key,
    this.nome = 'Pilar Brandão',
    this.papel = 'Aluno',
    this.ra = '24012345',
    this.curso = 'Sistemas de Informação',
    this.periodo = '6o semestre',
  });

  final String nome, papel, ra, curso, periodo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          children: [
            Text('Carteirinha digital', style: urbanist(size: 26, weight: FontWeight.bold, color: AppColors.branco)),
            const SizedBox(height: 4),
            Text('Aproxime do leitor NFC para validar',
                style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.white70)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.amarelo,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.creme,
                          child: Icon(Icons.person_outline, size: 48, color: AppColors.preto),
                        ),
                        const SizedBox(height: 14),
                        Text(nome, style: urbanist(size: 24, weight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.fundo, borderRadius: BorderRadius.circular(8)),
                          child: Text(papel, style: urbanist(size: 13, color: AppColors.amarelo)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: AppColors.creme,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Dado('RA', ra),
                        _Dado('Curso', curso),
                        _Dado('Período', periodo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi, color: AppColors.amarelo, size: 20),
                const SizedBox(width: 8),
                Text('NFC ativo', style: urbanist(size: 14, color: AppColors.amarelo)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado(this.rotulo, this.valor);

  final String rotulo, valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: urbanist(size: 11, weight: FontWeight.w400, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(valor, style: urbanist(size: 17)),
        ],
      ),
    );
  }
}
