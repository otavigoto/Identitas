import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

class NfcReadException implements Exception {
  const NfcReadException(this.message);

  final String message;

  @override
  String toString() => message;
}

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

  Future<String> lerUid() async {
    if (!await estaDisponivel()) {
      throw const NfcReadException(
        'NFC indisponível neste dispositivo. Ative o NFC e tente novamente.',
      );
    }

    final uidCompleter = Completer<String>();
    unawaited(
      lerCartao(
        onTagLida: (tag) {
          if (uidCompleter.isCompleted) return;
          final uid = uidDoTag(tag);
          if (uid == null) {
            uidCompleter.completeError(
              const NfcReadException('Não foi possível identificar o cartão.'),
            );
          } else {
            uidCompleter.complete(uid);
          }
        },
        onErro: () {
          if (!uidCompleter.isCompleted) {
            uidCompleter.completeError(
              const NfcReadException('Não foi possível ler o cartão NFC.'),
            );
          }
        },
      ).catchError((Object error) {
        if (!uidCompleter.isCompleted) {
          uidCompleter.completeError(
            NfcReadException('Não foi possível iniciar a leitura NFC: $error'),
          );
        }
      }),
    );

    try {
      return await uidCompleter.future.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      await parar();
      throw const NfcReadException(
        'Tempo esgotado. Aproxime o cartão e tente novamente.',
      );
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
