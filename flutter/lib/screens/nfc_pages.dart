import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:identitas/services/nfc_service.dart';

import 'package:identitas/widgets/nfc_scaffold.dart';


class NfcInstrucaoPage extends StatefulWidget {
  const NfcInstrucaoPage({
    super.key,
    required this.nomeDisciplina,
    required this.onValidarPresenca,
    this.nfcService,
  });

  final String nomeDisciplina;
  final Future<bool> Function(String tagUid) onValidarPresenca;
  final NfcService? nfcService;

  @override
  State<NfcInstrucaoPage> createState() => _NfcInstrucaoPageState();
}

class _NfcInstrucaoPageState extends State<NfcInstrucaoPage> {
  late final NfcService _nfc = widget.nfcService ?? NfcService();
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    _aguardarCartao();
  }

  @override
  void dispose() {
    _nfc.parar();
    super.dispose();
  }

  Future<void> _aguardarCartao() async {
    final disponivel = await _nfc.estaDisponivel();
    if (!mounted || _cancelando) return;

    if (!disponivel) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        nfcRoute(
          NfcErroPage(
            nomeDisciplina: widget.nomeDisciplina,
            onValidarPresenca: widget.onValidarPresenca,
            nfcService: _nfc,
            mensagem:
                'NFC indisponível neste dispositivo. Use um aparelho compatível e tente novamente.',
          ),
        ),
      );
      return;
    }

    await _nfc.lerCartao(
      onTagLida: (tag) {
        if (!mounted || _cancelando) return;
        final tagUid = NfcService.uidDoTag(tag);
        if (tagUid == null) {
          Navigator.of(context).pushReplacement(
            nfcRoute(
              NfcErroPage(
                nomeDisciplina: widget.nomeDisciplina,
                onValidarPresenca: widget.onValidarPresenca,
                nfcService: _nfc,
                mensagem: 'Não foi possível identificar o cartão NFC.',
              ),
            ),
          );
          return;
        }
        Navigator.of(context).pushReplacement(
          nfcRoute(
            NfcLendoPage(
              tagUid: tagUid,
              nomeDisciplina: widget.nomeDisciplina,
              onValidarPresenca: widget.onValidarPresenca,
              nfcService: _nfc,
            ),
          ),
        );
      },
      onErro: () {
        if (!mounted || _cancelando) return;
        Navigator.of(context).pushReplacement(
          nfcRoute(
            NfcErroPage(
              nomeDisciplina: widget.nomeDisciplina,
              onValidarPresenca: widget.onValidarPresenca,
              nfcService: _nfc,
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelar() async {
    if (_cancelando) return;
    setState(() => _cancelando = true);
    await _nfc.parar();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return NfcScaffold(
      cardChild: NfcStatusCard(
        title: 'Aproxime o celular',
        subtitle: 'Mantenha a parte traseira próxima ao leitor.',
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/nfc_phone.svg',
              width: 44,
              height: 44,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1E1E1E),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            SvgPicture.asset(
              'assets/icons/nfc_waves.svg',
              width: 44,
              height: 44,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1E1E1E),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
      bottomButton: TextButton(
        key: const Key('nfc-cancelar'),
        onPressed: _cancelando ? null : _cancelar,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(_cancelando ? 'Cancelando...' : 'Cancelar'),
      ),
    );
  }
}


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

