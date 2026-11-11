import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/turmas_page.dart';

void main() {
  Future<void> abrirLista(
    WidgetTester tester, {
    Size size = const Size(402, 874),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TurmasPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('Lista as aulas mockadas', (tester) async {
    await abrirLista(tester);
    expect(find.text('Minhas aulas'), findsOneWidget);
    expect(find.text('Projeto Integrador VI'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Engenharia de Software'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsOneWidget);
  });

  testWidgets('Busca por disciplina e mostra estado vazio', (tester) async {
    await abrirLista(tester);
    await tester.enterText(find.byKey(const Key('busca-aula')), 'banco');
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsNothing);

    await tester.enterText(find.byKey(const Key('busca-aula')), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma aula encontrada.'), findsOneWidget);
  });

  testWidgets('Filtra por semestre', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.widgetWithText(FilterChip, '2026.1'));
    await tester.pumpAndSettle();
    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsNothing);
    // Tocar de novo remove o filtro.
    await tester.tap(find.widgetWithText(FilterChip, '2026.1'));
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados'), findsOneWidget);
  });

  testWidgets('Cria uma nova aula e valida campos obrigatórios', (
    tester,
  ) async {
    await abrirLista(tester);
    await tester.tap(find.byKey(const Key('nova-aula')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome da turma.'), findsOneWidget);
    expect(find.text('Informe a disciplina.'), findsOneWidget);
    expect(find.text('Informe o semestre.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('turma-nome')), 'Turma Z');
    await tester.enterText(
      find.byKey(const Key('turma-disciplina')),
      'Compiladores',
    );
    await tester.enterText(find.byKey(const Key('turma-semestre')), '2026.2');
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Minhas aulas'), findsOneWidget);
    expect(find.text('Compiladores'), findsOneWidget);
  });

  testWidgets('Edita uma aula pelo detalhe', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Banco de Dados'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhe da aula'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar aula'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('turma-disciplina')),
      'Banco de Dados II',
    );
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados II'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados II'), findsOneWidget);
  });

  testWidgets('Adiciona e remove alunos', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Engenharia de Software'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (0)'), findsOneWidget);
    expect(find.text('Nenhum aluno matriculado.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adicionar-aluno')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Souza'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (1)'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover Ana Souza'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (0)'), findsOneWidget);
  });

  testWidgets('Exclui uma aula após confirmar', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Redes de Computadores'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir aula'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-excluir')));
    await tester.pumpAndSettle();
    expect(find.text('Minhas aulas'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsNothing);
    expect(find.text('Banco de Dados'), findsOneWidget);
  });

  testWidgets('Tela pequena não gera overflow', (tester) async {
    await abrirLista(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
