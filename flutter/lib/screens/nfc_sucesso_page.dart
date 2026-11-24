import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'nfc_scaffold.dart';

class NfcSucessoPage extends StatelessWidget {
  const NfcSucessoPage({
    super.key,
    required this.nomeDisciplina,
  });

  final String nomeDisciplina;

  @override
  Widget build(BuildContext context) {
    return NfcScaffold(
      cardChild: NfcStatusCard(
        title: 'Presença confirmada',
        subtitle: nomeDisciplina,
        iconColor: const Color(0xFF1B7A2E),
        icon: SvgPicture.asset(
          'assets/icons/nfc_check.svg',
          width: 64,
          height: 64,
          colorFilter: const ColorFilter.mode(
            Color(0xFF1B7A2E),
            BlendMode.srcIn,
          ),
          semanticsLabel: 'Presença confirmada',
        ),
      ),
      bottomButton: FilledButton(
        key: const Key('nfc-concluir'),
        onPressed: () => Navigator.of(context).pop(true),
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
        child: const Text('Concluir'),
      ),
    );
  }
}