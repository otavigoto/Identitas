import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

class NfcService {
  bool _ativo = false;

  static String? uidDoTag(NfcTag tag) {
    final identifier = switch (defaultTargetPlatform) {
      TargetPlatform.android => NfcTagAndroid.from(tag)?.id,
      TargetPlatform.iOS =>
        MiFareIos.from(tag)?.identifier ?? Iso7816Ios.from(tag)?.identifier,
      _ => null,
    };
    return identifier
        ?.map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Future<bool> estaDisponivel() async {
    try {
      final status = await NfcManager.instance.checkAvailability();
      return status == NfcAvailability.enabled;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> lerCartao({
    required void Function(NfcTag tag) onTagLida,
    required VoidCallback onErro,
  }) async {
    _ativo = true;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        alertMessageIos: 'Aproxime seu celular do leitor NFC',
        onSessionErrorIos: (_) {
          _ativo = false;
          onErro();
        },
        onDiscovered: (tag) async {
          await parar();
          onTagLida(tag);
        },
      );
    } on MissingPluginException {
      _ativo = false;
      onErro();
    } on PlatformException {
      _ativo = false;
      onErro();
    }
  }

  Future<void> parar() async {
    if (!_ativo) return;
    _ativo = false;
    await NfcManager.instance.stopSession();
  }
}
