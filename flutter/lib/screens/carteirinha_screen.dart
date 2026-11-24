import 'package:flutter/material.dart';

import 'screens_shared.dart';

class CarteirinhaScreen extends StatelessWidget {
  const CarteirinhaScreen({
    super.key,
    this.nome = 'Pilar Brandão',
    this.papel = 'Aluno',
    this.ra = '24012345',
    this.curso = 'Sistemas de Informação',
    this.periodo = '6º semestre',
  });

  final String nome;
  final String papel;
  final String ra;
  final String curso;
  final String periodo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IdentitasColors.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Carteirinha digital'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Aproxime do leitor NFC para validar',
              style: identitasText(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: IdentitasColors.amarelo,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            color: IdentitasColors.creme,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 52,
                            color: IdentitasColors.preto,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          nome,
                          style: identitasText(
                            size: 24,
                            weight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: IdentitasColors.fundo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            papel,
                            style: identitasText(
                              size: 13,
                              color: IdentitasColors.amarelo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: IdentitasColors.creme,
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
                const Icon(
                  Icons.contactless,
                  color: IdentitasColors.amarelo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'NFC ativo',
                  style: identitasText(
                    size: 14,
                    color: IdentitasColors.amarelo,
                  ),
                ),
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

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: identitasText(
              size: 11,
              weight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: identitasText(size: 17, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
