import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/main.dart';

void main() {
  Future<void> openLogin(
    WidgetTester tester, {
    Size size = const Size(402, 874),
    double keyboard = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  final identifier = find.byKey(const Key('login-identifier'));
  final password = find.byKey(const Key('login-password'));
  // Título da lista de aulas, exibida após o login.
  const message = 'Minhas aulas';

  testWidgets('Exibe a tela e exige os dois campos', (tester) async {
    await openLogin(tester);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Email / RA'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu email ou RA.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(find.text(message), findsNothing);
  });

  testWidgets('Alterna a senha sem perder seu conteúdo', (tester) async {
    await openLogin(tester);
    await tester.enterText(password, 'senha123');
    expect(tester.widget<TextFormField>(password).controller!.text, 'senha123');
    EditableText field() => tester.widget<EditableText>(
      find.descendant(of: password, matching: find.byType(EditableText)),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pumpAndSettle();
    expect(field().obscureText, isFalse);
    expect(field().controller.text, 'senha123');
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pumpAndSettle();
    expect(field().obscureText, isTrue);
  });

  for (final login in ['aluno@instituicao.edu.br', '24012345']) {
    testWidgets('Aceita $login e abre a lista de aulas', (tester) async {
      await openLogin(tester);
      await tester.enterText(identifier, login);
      await tester.enterText(password, 'senha123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  }

  testWidgets('Avança e envia pelo teclado', (tester) async {
    await openLogin(tester);
    await tester.enterText(identifier, '24012345');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final field = tester.widget<EditableText>(
      find.descendant(of: password, matching: find.byType(EditableText)),
    );
    expect(field.focusNode.hasFocus, isTrue);
    await tester.enterText(password, 'senha123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('Rejeita identificador em branco', (tester) async {
    await openLogin(tester);
    await tester.enterText(identifier, '   ');
    await tester.enterText(password, 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu email ou RA.'), findsOneWidget);
    expect(find.text(message), findsNothing);
  });

  testWidgets('Tela pequena e teclado permitem rolar e validar sem overflow', (
    tester,
  ) async {
    await openLogin(tester, size: const Size(320, 568), keyboard: 280);
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe sua senha.'), findsOneWidget);
    await tester.ensureVisible(password);
    expect(tester.takeException(), isNull);
  });
}
