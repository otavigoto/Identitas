import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/api_client.dart';
import 'package:identitas/professor_api.dart';
import 'package:identitas/services/nfc_service.dart';
import 'package:identitas/turmas_api.dart';
import 'package:identitas/turmas_page.dart';
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

/// Backend falso em memória, com o mesmo formato de resposta de `/classes`.
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
  int _proximoId = 10;
  bool offline = false;

  /// IDs matriculados que não existem mais como usuário (vêm em
  /// `missingStudents`).
  final Set<String> alunosOrfaos = {};
  final List<http.Request> requisicoes = [];
  List<Map<String, dynamic>>? chamadaEnviada;

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
    final partes = req.url.pathSegments; // ex.: [classes, 1, students, 24]
    final body = req.body.isEmpty ? null : jsonDecode(req.body);

    Map<String, dynamic>? achar(String id) {
      for (final t in turmas) {
        if (t['_id'] == id) return t;
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
    if (req.method == 'POST' && partes.length == 1) {
      final nova = _turma(
        '${_proximoId++}',
        body['name'] as String,
        body['week'] as String,
        body['startTime'] as String,
        body['endTime'] as String,
        [],
      );
      turmas.add(nova);
      return json(nova, 201);
    }
    final turma = partes.length >= 2 ? achar(partes[1]) : null;
    if (turma == null) {
      return json({'message': 'Turma não encontrada.'}, 404);
    }
    if (req.method == 'PATCH' && partes.length == 4 && partes[3] == 'open') {
      turma['attendanceStatus'] = 'open';
      return json(turma);
    }
    if (req.method == 'PATCH' &&
        partes.length == 4 &&
        partes[2] == 'attendance' &&
        partes[3] == 'close') {
      turma['attendanceStatus'] = 'closed';
      return json(turma);
    }
    if (req.method == 'POST' && partes.length == 5 && partes[4] == 'nfc') {
      return json(turma);
    }
    if (req.method == 'PATCH') {
      turma.addAll((body as Map).cast<String, dynamic>());
      return json(turma);
    }
    if (req.method == 'DELETE' && partes.length == 2) {
      turmas.remove(turma);
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
      chamadaEnviada = [
        for (final item in (body['students'] as List<dynamic>))
          (item as Map<String, dynamic>),
      ];
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
    if (req.method == 'POST' && partes[2] == 'students') {
      for (final id in (body['enrolledStudents'] as List).cast<String>()) {
        if (!alunos.contains(id)) alunos.add(id);
      }
      return json(turma);
    }
    if (req.method == 'DELETE' && partes[2] == 'students') {
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
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  testWidgets('Carrega as aulas vindas da API', (tester) async {
    await abrirLista(tester);
    expect(find.text('Minhas disciplinas'), findsOneWidget);
    expect(find.text('Projeto Integrador VI'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsOneWidget);
  });

  testWidgets('Mostra erro e permite tentar novamente', (tester) async {
    backend.offline = true;
    await abrirLista(tester);
    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    expect(find.text('Projeto Integrador VI'), findsNothing);

    backend.offline = false;
    await tester.tap(find.byKey(const Key('tentar-novamente')));
    await tester.pumpAndSettle();
    expect(find.text('Projeto Integrador VI'), findsOneWidget);
  });

  testWidgets('Avisa quando não há professor logado', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final api = TurmasApi(clienteDe(backend, professorId: null));
    await tester.pumpWidget(MaterialApp(home: TurmasPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Faça login para continuar.'), findsOneWidget);
  });

  testWidgets('Busca por nome e mostra estado vazio', (tester) async {
    await abrirLista(tester);
    await tester.enterText(find.byKey(const Key('busca-aula')), 'banco');
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsNothing);

    await tester.enterText(find.byKey(const Key('busca-aula')), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma aula encontrada.'), findsOneWidget);
  });

  testWidgets('Filtra por dia da semana', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Quarta-feira'));
    await tester.pumpAndSettle();
    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Quarta-feira'));
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados'), findsOneWidget);
  });

  testWidgets('Cria uma aula, valida campos e grava no backend', (
    tester,
  ) async {
    await abrirLista(tester);
    await tester.tap(find.byKey(const Key('nova-aula')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Informe a disciplina.'), findsOneWidget);
    expect(find.text('Informe o dia da semana.'), findsOneWidget);
    expect(find.text('Informe o horário de início.'), findsOneWidget);
    expect(find.text('Informe o horário de fim.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('turma-nome')), 'Compiladores');
    await tester.enterText(find.byKey(const Key('turma-dia')), 'Sexta-feira');
    await tester.enterText(find.byKey(const Key('turma-inicio')), '8h');
    await tester.enterText(find.byKey(const Key('turma-fim')), '09:40');
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Use o formato HH:mm (ex: 08:30).'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('turma-inicio')), '08:00');
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Minhas disciplinas'), findsOneWidget);
    expect(find.text('Compiladores'), findsOneWidget);
    final enviada = jsonDecode(
      backend.requisicoes.lastWhere((r) => r.method == 'POST').body,
    );
    expect(enviada['id_professor'], 'prof1');
    expect(enviada['attendanceStatus'], 'closed');
    expect(enviada['startTime'], '08:00');
    expect(backend.turmas.any((t) => t['name'] == 'Compiladores'), true);
  });

  testWidgets('Edita uma aula pelo detalhe', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Banco de Dados'));
    await tester.pumpAndSettle();
    expect(find.text('Gestão da disciplina'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar aula'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('turma-nome')),
      'Banco de Dados II',
    );
    await tester.tap(find.byKey(const Key('turma-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados II'), findsOneWidget);
    expect(backend.turmas[1]['name'], 'Banco de Dados II');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados II'), findsOneWidget);
  });

  testWidgets(
    'Abre a chamada e o fluxo NFC do detalhe; avisa se NFC indisponível',
    (tester) async {
      await abrirLista(tester, nfcService: _NfcIndisponivel());
      await tester.tap(find.text('Projeto Integrador VI'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('validar-presenca')));
      await tester.pumpAndSettle();

      expect(
        backend.requisicoes.any(
          (r) =>
              r.method == 'PATCH' && r.url.path == '/classes/1/attendance/open',
        ),
        isTrue,
      );
      expect(
        find.text(
          'NFC indisponível neste dispositivo. Ajuste a presença manualmente.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chamada-confirmar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pausa e retoma leitura NFC sem sair da gestão', (tester) async {
    await abrirLista(tester, nfcService: _NfcAguardandoCartao());
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();

    expect(find.text('Aproxime os cartões NFC dos alunos.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chamada-alternar-leitura')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Leitura pausada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chamada-alternar-leitura')));
    await tester.pumpAndSettle();
    expect(find.text('Aproxime os cartões NFC dos alunos.'), findsOneWidget);
  });

  testWidgets('Ajusta presença e envia a lista completa antes de fechar', (
    tester,
  ) async {
    await abrirLista(tester, nfcService: _NfcIndisponivel());
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('ajustar-24012345')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ajustar-24012345')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Presente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chamada-confirmar')));
    await tester.pumpAndSettle();

    expect(backend.chamadaEnviada, [
      {'studentId': '24012345', 'present': true},
      {'studentId': '24012346', 'present': false},
    ]);
    expect(
      backend.requisicoes.any(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/classes/1/attendance/close',
      ),
      isTrue,
    );
    expect(find.text('Chamada registrada com sucesso.'), findsOneWidget);
  });

  testWidgets('Lista alunos com nome e RA, remove um e não oferece adicionar', (
    tester,
  ) async {
    await abrirLista(tester);
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (2)'), findsOneWidget);
    expect(find.text('Nome 24012345'), findsOneWidget);
    expect(find.text('RA 24012345'), findsOneWidget);
    expect(find.text('Aluno 24012345'), findsNothing);
    expect(find.byKey(const Key('adicionar-aluno')), findsNothing);
    expect(find.text('Adicionar'), findsNothing);

    await tester.tap(find.byTooltip('Remover Nome 24012345'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (1)'), findsOneWidget);
    expect(find.text('Nome 24012345'), findsNothing);
    expect(backend.turmas[0]['enrolledStudents'], ['24012346']);
  });

  testWidgets('Turma sem alunos mostra o estado vazio', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Banco de Dados'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (0)'), findsOneWidget);
    expect(find.text('Nenhum aluno matriculado.'), findsOneWidget);
  });

  testWidgets('Remove sozinho o aluno que não existe mais e avisa', (
    tester,
  ) async {
    backend.alunosOrfaos.add('24012345');
    await abrirLista(tester);
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();

    expect(find.text('1 aluno removido, não encontrado.'), findsOneWidget);
    expect(find.text('Alunos (1)'), findsOneWidget);
    expect(find.textContaining('24012345'), findsNothing);
    expect(find.text('Nome 24012346'), findsOneWidget);
    expect(find.text('RA 24012346'), findsOneWidget);
    expect(backend.turmas[0]['enrolledStudents'], ['24012346']);
  });

  testWidgets('Remove vários ausentes e conta no aviso', (tester) async {
    backend.alunosOrfaos.addAll(['24012345', '24012346']);
    await abrirLista(tester);
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();

    expect(find.text('2 alunos removidos, não encontrados.'), findsOneWidget);
    expect(find.text('Alunos (0)'), findsOneWidget);
    expect(find.text('Nenhum aluno matriculado.'), findsOneWidget);
    expect(backend.turmas[0]['enrolledStudents'], isEmpty);
  });

  testWidgets('Sem alunos ausentes não mostra aviso', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-alunos')), findsNothing);
    expect(find.text('Alunos (2)'), findsOneWidget);
  });

  testWidgets('Exclui uma aula após confirmar', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Redes de Computadores'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir aula'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-excluir')));
    await tester.pumpAndSettle();
    expect(find.text('Minhas disciplinas'), findsOneWidget);
    expect(find.text('Redes de Computadores'), findsNothing);
    expect(backend.turmas.length, 2);
  });

  testWidgets('Tela pequena não gera overflow', (tester) async {
    await abrirLista(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
