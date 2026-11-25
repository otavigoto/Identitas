import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/screens/nfc_pages.dart';
import 'package:identitas/services/nfc_service.dart';

void main() {
  testWidgets('Abre sucesso quando o servidor confirma a presença', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NfcLendoPage(
          tagUid: 'A1B2C3',
          nomeDisciplina: 'Banco de Dados',
          onValidarPresenca: (_) async => true,
          nfcService: NfcService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Presença confirmada'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
  });

  testWidgets('Mostra a falha retornada pela validação de presença', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NfcLendoPage(
          tagUid: 'A1B2C3',
          nomeDisciplina: 'Banco de Dados',
          onValidarPresenca: (_) async => throw Exception('API indisponível'),
          nfcService: NfcService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('API indisponível'), findsOneWidget);
  });

  testWidgets('Cancela a validação pendente e retorna à tela anterior', (
    tester,
  ) async {
    final validacaoPendente = Completer<bool>();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Turma')),
      ),
    );
    unawaited(
      navigatorKey.currentState!.push<void>(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              NfcLendoPage(
                tagUid: 'A1B2C3',
                nomeDisciplina: 'Banco de Dados',
                onValidarPresenca: (_) => validacaoPendente.future,
                nfcService: NfcService(),
              ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Lendo cartão'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nfc-cancelar')));
    await tester.pumpAndSettle();

    expect(find.text('Turma'), findsOneWidget);
    validacaoPendente.complete(true);
    await tester.pump();
    expect(find.text('Turma'), findsOneWidget);
  });
}
