import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/nfc_service.dart';
import 'nfc_erro_page.dart';
import 'nfc_lendo_page.dart';
import 'nfc_scaffold.dart';

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
      cardChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/nfc_phone.svg',
                width: 44,
                height: 68,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1E1E1E),
                  BlendMode.srcIn,
                ),
                semanticsLabel: 'Celular',
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/nfc_waves.svg',
                    width: 48,
                    height: 36,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1E1E1E),
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'Leitor NFC',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Leitor NFC',
                    style: TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Aproxime seu celular do\nleitor NFC',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mantenha o celular próximo até concluir',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5C5B4D),
              fontSize: 13,
            ),
          ),
        ],
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