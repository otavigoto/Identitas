import 'package:flutter/material.dart';
import 'package:identitas/services/nfc_service.dart';
import 'nfc_instrucao_page.dart';
import '../widgets/nfc_scaffold.dart';

class NfcErroPage extends StatelessWidget {
  const NfcErroPage({
    super.key,
    required this.nomeDisciplina,
    required this.onValidarPresenca,
    required this.nfcService,
    this.mensagem = 'Aproxime novamente o celular do leitor',
  });

  final String nomeDisciplina;
  final Future<bool> Function(String tagUid) onValidarPresenca;
  final NfcService nfcService;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return NfcScaffold(
      cardChild: NfcStatusCard(
        title: 'Não foi possível validar',
        subtitle: mensagem,
        iconColor: const Color(0xFFB81D1D),
        icon: const Icon(
          Icons.cancel_outlined,
          size: 64,
          color: Color(0xFFB81D1D),
          semanticLabel: 'Falha na validação',
        ),
      ),
      bottomButton: FilledButton(
        key: const Key('nfc-tentar-novamente'),
        onPressed: () => Navigator.of(context).pushReplacement(
          nfcRoute(
            NfcInstrucaoPage(
              nomeDisciplina: nomeDisciplina,
              onValidarPresenca: onValidarPresenca,
              nfcService: nfcService,
            ),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF9FF2E),
          foregroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Tentar novamente'),
      ),
    );
  }
}