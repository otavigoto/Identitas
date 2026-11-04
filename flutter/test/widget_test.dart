import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/screens/home_screen.dart';

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
}
