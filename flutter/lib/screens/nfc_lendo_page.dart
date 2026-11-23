import 'package:flutter/material.dart';
import 'package:identitas/services/nfc_service.dart';
import 'nfc_erro_page.dart';
import '../widgets/nfc_scaffold.dart';
import 'nfc_sucesso_page.dart';

class NfcLendoPage extends StatefulWidget {
  const NfcLendoPage({
    super.key,
    required this.tagUid,
    required this.nomeDisciplina,
    required this.onValidarPresenca,
    required this.nfcService,
  });

  final String tagUid;
  final String nomeDisciplina;
  final Future<bool> Function(String tagUid) onValidarPresenca;
  final NfcService nfcService;

  @override
  State<NfcLendoPage> createState() => _NfcLendoPageState();
}

class _NfcLendoPageState extends State<NfcLendoPage> {
  @override
  void initState() {
    super.initState();
    _enviarParaApi();
  }

  Future<void> _enviarParaApi() async {
    var sucesso = false;
    var mensagemErro = 'Não foi possível validar a presença.';
    try {
      sucesso = await widget.onValidarPresenca(widget.tagUid);
    } on Exception catch (error) {
      mensagemErro = error.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    if (sucesso) {
      Navigator.of(context).pushReplacement(
        nfcRoute(NfcSucessoPage(nomeDisciplina: widget.nomeDisciplina)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      nfcRoute(
        NfcErroPage(
          nomeDisciplina: widget.nomeDisciplina,
          onValidarPresenca: widget.onValidarPresenca,
          nfcService: widget.nfcService,
          mensagem: mensagemErro,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NfcScaffold(
      cardChild: NfcStatusCard(
        title: 'Lendo cartão',
        subtitle: 'Não afaste o celular do leitor.',
        icon: const SizedBox.square(
          dimension: 72,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            color: Color(0xFF1E1E1E),
            backgroundColor: Color(0x331E1E1E),
            semanticsLabel: 'Lendo cartão NFC',
          ),
        ),
      ),
      bottomButton: TextButton(
        key: const Key('nfc-cancelar'),
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Text('Cancelar'),
      ),
    );
  }
}