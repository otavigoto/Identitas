import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/screens/cadastro_screen.dart';
import 'package:identitas/screens/gestao_disciplina_screen.dart';
import 'package:identitas/screens/historico_screen.dart';
import 'package:identitas/screens/home_screen.dart';
import 'package:identitas/screens/revisao_chamada_screen.dart';

void main() {
  testWidgets('Homepage mostra as aulas de hoje', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Resumo de Hoje'), findsOneWidget);
    expect(find.text('PRESENTE'), findsOneWidget);
    expect(find.text('PRÓXIMA'), findsOneWidget);
    expect(find.text('AGENDADO'), findsOneWidget);
  });

  testWidgets('Gestão da Disciplina filtra alunos por nome ou RA', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GestaoDisciplinaScreen()));

    await tester.enterText(find.byType(TextField), 'camila');
    await tester.pump();
    expect(find.text('Camila Oliveira'), findsOneWidget);
    expect(find.text('Ana Beatriz Lima'), findsNothing);

    await tester.enterText(find.byType(TextField), '24010001');
    await tester.pump();
    expect(find.text('Ana Beatriz Lima'), findsOneWidget);
    expect(find.text('Camila Oliveira'), findsNothing);
  });

  testWidgets('Revisão de Chamada move aluno ajustado para presentes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RevisaoChamadaScreen()));
    expect(find.text('Ausentes (2)'), findsOneWidget);

    await tester.tap(find.text('Ajustar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presente').last);
    await tester.tap(find.text('Salvar alteração'));
    await tester.pumpAndSettle();

    expect(find.text('Ausentes (1)'), findsOneWidget);
    expect(find.text('Presentes (7)'), findsOneWidget);
  });

  testWidgets('Histórico filtra por período', (tester) async {
    tester.view.physicalSize = const Size(402, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HistoricoScreen()));

    // Últimos 7 dias: o registro de 22 set. fica de fora.
    expect(find.text('22 set. 2026'), findsNothing);
    expect(find.text('06 out. 2026'), findsOneWidget);

    await tester.tap(find.text('Últimos 7 dias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Últimos 30 dias').last);
    await tester.pumpAndSettle();

    expect(find.text('22 set. 2026'), findsOneWidget);
  });

  testWidgets('Cadastro valida email e RA antes de enviar', (tester) async {
    tester.view.physicalSize = const Size(402, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));

    await tester.tap(find.text('Registre-se'));
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsNWidgets(4));

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Pilar Brandão');
    await tester.enterText(campos.at(1), 'PUC Campinas');
    await tester.enterText(campos.at(2), 'pilar-sem-arroba');
    await tester.enterText(campos.at(3), '24a');
    await tester.tap(find.text('Registre-se'));
    await tester.pump();
    expect(find.text('Email inválido'), findsOneWidget);
    expect(find.text('Use apenas números'), findsOneWidget);

    await tester.enterText(campos.at(2), 'pilar@puc.edu.br');
    await tester.enterText(campos.at(3), '24012345');
    await tester.tap(find.text('Registre-se'));
    await tester.pump();
    expect(find.text('Cadastro enviado'), findsOneWidget);
  });
}
