import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/services/api_service.dart';
import 'package:identitas/screens/login_page.dart';
import 'package:identitas/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Backend falso de `/auth`: RA `24012345` (aluno) e `0001` (professor),
  /// senha `senha123`.
  AuthApi fakeAuth() => AuthApi(
    ApiClient(
      baseUrl: 'http://api.teste',
      httpClient: MockClient((http.Request req) async {
        http.Response json(Object data, int status) => http.Response(
          jsonEncode(data),
          status,
          headers: {'content-type': 'application/json'},
        );
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (req.url.path != '/auth' || body['password'] != 'senha123') {
          return json({'message': 'RA ou senha inválidos.'}, 401);
        }
        final professor = body['ra'] == '0001';
        return json({
          'user': {
            '_id': professor ? 'p1' : 'a1',
            'name': professor ? 'Prof Teste' : 'Ana Aluna',
            'ra': body['ra'],
            'role': professor ? 'PROFESSOR' : 'STUDENT',
          },
          'accessToken': 'acc',
          'refreshToken': 'ref',
        }, 200);
      }),
    ),
  );

  ApiClient fakeProfessorClient() => ApiClient(
    baseUrl: 'http://api.teste',
    session: Session()
      ..accessToken = 'access-token'
      ..userId = 'p1'
      ..role = 'PROFESSOR',
    httpClient: MockClient((req) async {
      http.Response json(Object data, [int status = 200]) => http.Response(
        jsonEncode(data),
        status,
        headers: {'content-type': 'application/json'},
      );
      final classData = {
        'id': 'c1',
        'name': 'Banco de Dados',
        'id_professor': 'p1',
        'week': 'Segunda-feira',
        'startTime': '08:00',
        'endTime': '09:40',
      };
      if (req.method == 'GET' && req.url.path == '/classes/me/today') {
        return json({
          'user': {
            '_id': 'p1',
            'name': 'Prof Teste',
            'ra': '0001',
            'role': 'PROFESSOR',
          },
          'classes': [classData],
        });
      }
      if (req.method == 'GET' && req.url.path == '/classes/c1/students') {
        return json({
          'class': classData,
          'date': '2026-11-24T00:00:00.000Z',
          'attendanceRecorded': false,
          'totalStudents': 0,
          'present': 0,
          'absent': 0,
          'students': [],
          'missingStudents': [],
        });
      }
      if (req.method == 'GET' &&
          req.url.path == '/classes/c1/attendance/summary') {
        return json({
          'class': classData,
          'attendance': {
            'lessons': 0,
            'studentRecords': 0,
            'present': 0,
            'absent': 0,
            'percentage': 0,
          },
          'students': [],
          'missingStudents': [],
        });
      }
      return json({
        'message': 'Rota inesperada: ${req.method} ${req.url.path}',
      }, 404);
    }),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    final professorClient = fakeProfessorClient();
    await tester.pumpWidget(
      MyApp(
        home: LoginPage(
          auth: fakeAuth(),
          professorApi: ProfessorApi(professorClient),
          turmasApi: TurmasApi(professorClient),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final identifier = find.byKey(const Key('login-identifier'));
  final password = find.byKey(const Key('login-password'));
  const message = 'Aulas de hoje';
  const homeMessage = 'Identitas';
  const professorHomeMessage = 'Resumo de Hoje';

  testWidgets('Exibe a tela e exige os dois campos', (tester) async {
    await openLogin(tester);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('RA'), findsOneWidget);
    expect(find.text('Criar cadastro'), findsNothing);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu RA.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(find.text(homeMessage), findsNothing);
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

  testWidgets('Aluno entra com RA e senha e abre a home', (tester) async {
    await openLogin(tester);
    await tester.enterText(identifier, '24012345');
    await tester.enterText(password, 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text(homeMessage), findsOneWidget);
    expect(find.text(message), findsNothing);
    expect(find.text('Login'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Professor entra e abre a home com as aulas de hoje', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(identifier, '0001');
    await tester.enterText(password, 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text(professorHomeMessage), findsOneWidget);
    // Aparece no card da aula e, dependendo do horário, também em "Próxima Aula".
    expect(find.text('Banco de Dados'), findsWidgets);
    expect(find.byKey(const Key('professor-abrir-perfil')), findsOneWidget);
    expect(find.byKey(const Key('professor-ver-todas-aulas')), findsOneWidget);
    expect(find.text('PRESENTE'), findsNothing);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('Professor abre gestão ao tocar na matéria da home', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(identifier, '0001');
    await tester.enterText(password, 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('professor-disciplina-c1')));
    await tester.pumpAndSettle();

    expect(find.text('Gestão da Disciplina'), findsOneWidget);
    expect(find.textContaining('Banco de Dados'), findsOneWidget);
    expect(find.text('Frequência geral'), findsOneWidget);
  });

  testWidgets('Senha errada mostra o erro do servidor e fica no login', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(identifier, '24012345');
    await tester.enterText(password, 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('RA ou senha inválidos.'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text(homeMessage), findsNothing);
  });

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
    expect(find.text(homeMessage), findsOneWidget);
  });

  testWidgets('Rejeita identificador em branco', (tester) async {
    await openLogin(tester);
    await tester.enterText(identifier, '   ');
    await tester.enterText(password, 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu RA.'), findsOneWidget);
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
