import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/screens/turmas_page.dart';
import 'package:identitas/services/api_service.dart';
import 'package:identitas/services/nfc_service.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NfcIndisponivel extends NfcService {
  @override
  Future<bool> estaDisponivel() async => false;
}

class _NfcAguardandoCartao extends NfcService {
  @override
  Future<bool> estaDisponivel() async => true;

  @override
  Future<void> lerCartao({
    required void Function(NfcTag tag) onTagLida,
    required void Function() onErro,
  }) async {}
}

class FakeBackend {
  FakeBackend() {
    turmas = [
      _turma('1', 'Projeto Integrador VI', 'Segunda-feira', '19:00', '22:30', [
        '24012345',
        '24012346',
      ]),
      _turma('2', 'Banco de Dados', 'Terça-feira', '08:00', '09:40', []),
      _turma(
        '3',
        'Redes de Computadores',
        'Quarta-feira',
        '10:00',
        '11:40',
        [],
      ),
    ];
  }

  late List<Map<String, dynamic>> turmas;
  bool offline = false;
  int falhasAoFechar = 0;
  final Set<String> alunosOrfaos = {};
  final List<http.Request> requisicoes = [];
  List<String>? chamadaEnviada;

  static Map<String, dynamic> _turma(
    String id,
    String name,
    String week,
    String inicio,
    String fim,
    List<String> alunos,
  ) => {
    '_id': id,
    'name': name,
    'id_professor': 'prof1',
    'week': week,
    'startTime': inicio,
    'endTime': fim,
    'attendanceStatus': 'closed',
    'enrolledStudents': alunos,
  };

  Future<http.Response> handle(http.Request req) async {
    if (offline) throw http.ClientException('sem conexão');
    requisicoes.add(req);
    final partes = req.url.pathSegments;
    final body = req.body.isEmpty ? null : jsonDecode(req.body);

    Map<String, dynamic>? achar(String id) {
      for (final turma in turmas) {
        if (turma['_id'] == id) return turma;
      }
      return null;
    }

    http.Response json(Object? data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

    if (req.method == 'GET' && partes.length == 3 && partes[1] == 'teacher') {
      return json(turmas);
    }
    final turma = partes.length >= 2 ? achar(partes[1]) : null;
    if (turma == null) {
      return json({'message': 'Turma não encontrada.'}, 404);
    }
    if (req.method == 'PATCH' &&
        partes.length == 4 &&
        partes[2] == 'attendance' &&
        partes[3] == 'open') {
      turma['attendanceStatus'] = 'open';
      return json(turma);
    }
    if (req.method == 'PATCH' &&
        partes.length == 4 &&
        partes[2] == 'attendance' &&
        partes[3] == 'close') {
      if (falhasAoFechar > 0) {
        falhasAoFechar--;
        return json({'message': 'Falha ao encerrar a chamada.'}, 500);
      }
      turma['attendanceStatus'] = 'closed';
      return json(turma);
    }

    final alunos = (turma['enrolledStudents'] as List).cast<String>();
    if (req.method == 'GET' &&
        partes.length == 4 &&
        partes[2] == 'attendance' &&
        partes[3] == 'summary') {
      final encontrados = [
        for (final id in alunos)
          if (!alunosOrfaos.contains(id)) id,
      ];
      return json({
        'class': {
          'id': turma['_id'],
          'name': turma['name'],
          'id_professor': 'prof1',
          'week': turma['week'],
          'startTime': turma['startTime'],
          'endTime': turma['endTime'],
        },
        'attendance': {
          'lessons': 0,
          'studentRecords': 0,
          'present': 0,
          'absent': 0,
          'percentage': 0,
        },
        'students': [
          for (final id in encontrados)
            {
              'id': id,
              'name': 'Nome $id',
              'ra': id,
              'nfcUid': null,
              'attendance': {
                'lessons': 0,
                'present': 0,
                'absent': 0,
                'percentage': 0,
                'history': [],
              },
            },
        ],
        'missingStudents': [],
      });
    }
    if (req.method == 'POST' &&
        partes.length == 4 &&
        partes[2] == 'students' &&
        partes[3] == 'attendance') {
      chamadaEnviada = (body['presentStudentIds'] as List<dynamic>)
          .cast<String>();
      return json(turma);
    }
    if (req.method == 'GET' && partes.length == 3 && partes[2] == 'students') {
      final encontrados = [
        for (final id in alunos)
          if (!alunosOrfaos.contains(id)) id,
      ];
      return json({
        'missingStudents': [
          for (final id in alunos)
            if (alunosOrfaos.contains(id))
              {'id': id, 'message': 'Aluno não encontrado.'},
        ],
        'class': {
          'id': turma['_id'],
          'name': turma['name'],
          'id_professor': 'prof1',
          'week': turma['week'],
          'startTime': turma['startTime'],
          'endTime': turma['endTime'],
        },
        'date': '2026-11-23T00:00:00.000Z',
        'attendanceRecorded': false,
        'totalStudents': encontrados.length,
        'present': 0,
        'absent': encontrados.length,
        'students': [
          for (final id in encontrados)
            {
              'id': id,
              'name': 'Nome $id',
              'ra': id,
              'nfcUid': null,
              'present': false,
            },
        ],
      });
    }
    if (req.method == 'DELETE' &&
        partes.length == 4 &&
        partes[2] == 'students') {
      alunos.remove(Uri.decodeComponent(partes[3]));
      return json(turma);
    }
    return json({'message': 'Rota inesperada'}, 500);
  }
}

ApiClient clienteDe(FakeBackend backend, {String? professorId = 'prof1'}) =>
    ApiClient(
      httpClient: MockClient(backend.handle),
      baseUrl: 'http://api.teste',
      session: Session()
        ..accessToken = 'token-teste'
        ..refreshToken = 'refresh-teste'
        ..userId = professorId
        ..role = 'PROFESSOR',
    );

void main() {
  late FakeBackend backend;

  Future<void> abrirLista(
    WidgetTester tester, {
    Size size = const Size(402, 874),
    NfcService? nfcService,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final client = clienteDe(backend);
    await tester.pumpWidget(
      MaterialApp(
        home: TurmasPage(
          nfcService: nfcService,
          api: TurmasApi(client),
          professorApi: ProfessorApi(client),
          periodSemester: '6',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  testWidgets('agrupa disciplinas por dia e mostra o semestre', (tester) async {
    await abrirLista(tester);
    expect(find.text('Disciplinas Matriculadas'), findsOneWidget);
    expect(find.text('6º semestre'), findsOneWidget);
    expect(find.text('SEGUNDA-FEIRA'), findsOneWidget);
    expect(find.text('Projeto Integrador VI'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('disciplinas-por-dia')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('TERÇA-FEIRA'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
  });

  testWidgets('recarrega as disciplinas ao puxar a tela para baixo', (
    tester,
  ) async {
    await abrirLista(tester);

    await tester.drag(
      find.byKey(const Key('disciplinas-por-dia')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();

    expect(
      backend.requisicoes
          .where(
            (request) =>
                request.method == 'GET' &&
                request.url.path == '/classes/teacher/prof1',
          )
          .length,
      2,
    );
  });

  testWidgets('abre gestão da disciplina e carrega frequência dos alunos', (
    tester,
  ) async {
    await abrirLista(tester);
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();

    expect(find.text('Gestão da Disciplina'), findsOneWidget);
    expect(find.text('Frequência geral'), findsOneWidget);
    expect(find.text('2 alunos matriculados'), findsOneWidget);
    expect(find.text('Nome 24012345'), findsOneWidget);
    expect(find.text('RA 24012345'), findsOneWidget);
    expect(find.byKey(const Key('buscar-aluno-chamada')), findsOneWidget);
    expect(find.byKey(const Key('validar-presenca')), findsOneWidget);
  });

  testWidgets('busca alunos por nome ou RA', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('buscar-aluno-chamada')),
      '24012346',
    );
    await tester.pumpAndSettle();

    expect(find.text('Nome 24012346'), findsOneWidget);
    expect(find.text('Nome 24012345'), findsNothing);
  });

  testWidgets('mostra erro e permite tentar novamente', (tester) async {
    backend.offline = true;
    await abrirLista(tester);
    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    expect(find.text('SEGUNDA-FEIRA'), findsNothing);

    backend.offline = false;
    await tester.tap(find.byKey(const Key('tentar-novamente')));
    await tester.pumpAndSettle();
    expect(find.text('Projeto Integrador VI'), findsOneWidget);
  });

  testWidgets('avisa quando não há professor logado', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final api = TurmasApi(clienteDe(backend, professorId: null));
    await tester.pumpWidget(MaterialApp(home: TurmasPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Faça login para continuar.'), findsOneWidget);
  });

  testWidgets('revisa chamada e envia apenas os alunos presentes', (
    tester,
  ) async {
    await abrirLista(tester, nfcService: _NfcIndisponivel());
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();

    expect(
      backend.requisicoes.any(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/classes/1/attendance/open',
      ),
      isTrue,
    );
    expect(find.textContaining('NFC indisponível'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chamada-ver-revisao')));
    await tester.pumpAndSettle();
    expect(find.text('Revisão de Chamada'), findsOneWidget);
    expect(find.text('Leitura NFC encerrada'), findsOneWidget);
    expect(find.text('Ausentes (2)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('ajustar-24012345')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ajustar-24012345')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presente'));
    await tester.tap(find.byKey(const Key('salvar-ajuste-presenca')));
    await tester.pumpAndSettle();
    expect(find.text('Presentes (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chamada-confirmar')));
    await tester.pumpAndSettle();
    expect(backend.chamadaEnviada, ['24012345']);
    final requisicoesDaChamada = backend.requisicoes
        .where(
          (request) =>
              request.url.path.endsWith('/attendance/open') ||
              request.url.path.endsWith('/students/attendance') ||
              request.url.path.endsWith('/attendance/close'),
        )
        .toList();
    expect(requisicoesDaChamada.map((request) => request.url.path).toList(), [
      '/classes/1/attendance/open',
      '/classes/1/attendance/open',
      '/classes/1/students/attendance',
      '/classes/1/attendance/close',
    ]);
    expect(
      backend.requisicoes.any(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/classes/1/attendance/close',
      ),
      isTrue,
    );
    expect(find.text('Gestão da Disciplina'), findsOneWidget);
  });

  testWidgets('permite tentar novamente o PATCH após salvar a presença', (
    tester,
  ) async {
    backend.falhasAoFechar = 1;
    await abrirLista(tester, nfcService: _NfcIndisponivel());
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chamada-ver-revisao')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chamada-confirmar')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Presença salva, mas não foi possível encerrar a chamada',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(
      backend.requisicoes.where(
        (request) =>
            request.method == 'POST' &&
            request.url.path == '/classes/1/students/attendance',
      ),
      hasLength(1),
    );

    await tester.tap(find.byKey(const Key('chamada-confirmar')));
    await tester.pumpAndSettle();
    expect(
      backend.requisicoes.where(
        (request) =>
            request.method == 'POST' &&
            request.url.path == '/classes/1/students/attendance',
      ),
      hasLength(1),
    );
    expect(
      backend.requisicoes.where(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/classes/1/attendance/close',
      ),
      hasLength(2),
    );
    expect(find.text('Gestão da Disciplina'), findsOneWidget);
  });

  testWidgets('encerra leitura e o botão voltar retorna à gestão', (
    tester,
  ) async {
    await abrirLista(tester, nfcService: _NfcAguardandoCartao());
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();

    expect(find.text('Aproxime os cartões NFC'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chamada-finalizar-leitura')));
    await tester.pumpAndSettle();
    expect(find.text('Leitura NFC encerrada'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Gestão da Disciplina'), findsOneWidget);
    expect(find.byKey(const Key('chamada-ver-revisao')), findsOneWidget);
  });

  testWidgets('remove alunos órfãos antes da chamada', (tester) async {
    backend.alunosOrfaos.add('24012345');
    await abrirLista(tester);
    await tester.tap(find.byKey(const Key('disciplina-1')));
    await tester.pumpAndSettle();

    expect(find.text('1 aluno matriculado'), findsOneWidget);
    expect(find.text('Nome 24012345'), findsNothing);
    expect(find.text('Nome 24012346'), findsOneWidget);
    expect(backend.turmas[0]['enrolledStudents'], ['24012346']);
  });

  testWidgets('disciplina sem alunos mostra zero e desabilita chamada', (
    tester,
  ) async {
    await abrirLista(tester);
    await tester.drag(
      find.byKey(const Key('disciplinas-por-dia')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('disciplinas-por-dia')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('disciplina-3')));
    await tester.pumpAndSettle();

    expect(find.text('0 alunos matriculados'), findsOneWidget);
    expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
  });

  testWidgets('tela estreita não gera overflow', (tester) async {
    await abrirLista(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
