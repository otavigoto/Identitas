import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identitas/services/nfc_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/turmas_api.dart';
import 'package:identitas/turmas_page.dart';
import 'package:nfc_manager/nfc_manager.dart';

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
      _turma('1', 'Turma A - Noite', 'Projeto Integrador VI', '2026.2', [
        '24012345',
        '24012346',
      ]),
      _turma('2', 'Turma B - Manhã', 'Banco de Dados', '2026.2', []),
      _turma('3', 'Turma A - Manhã', 'Redes de Computadores', '2026.1', []),
    ];
  }

  late List<Map<String, dynamic>> turmas;
  int _proximoId = 10;
  bool offline = false;

  static Map<String, dynamic> _turma(
    String id,
    String nome,
    String disciplina,
    String semestre,
    List<String> alunos,
  ) => {
    '_id': id,
    'nome': nome,
    'disciplina': disciplina,
    'semestre': semestre,
    'id_professor': 'prof1',
    'listaAlunos': alunos,
  };

  Future<http.Response> handle(http.Request req) async {
    if (offline) throw http.ClientException('sem conexão');
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
        body['nome'] as String,
        body['disciplina'] as String,
        body['semestre'] as String,
        [],
      );
      turmas.add(nova);
      return json(nova, 201);
    }
    final turma = partes.length >= 2 ? achar(partes[1]) : null;
    if (turma == null) {
      return json({'message': 'Turma não encontrada.'}, 404);
    }
    if (req.method == 'PATCH') {
      turma.addAll((body as Map).cast<String, dynamic>());
      return json(turma);
    }
    if (req.method == 'DELETE' && partes.length == 2) {
      turmas.remove(turma);
      return json(turma);
    }
    final alunos = (turma['listaAlunos'] as List).cast<String>();
    if (req.method == 'POST' && partes[2] == 'students') {
      if (!alunos.contains(body['alunoId'])) alunos.add(body['alunoId']);
      return json(turma);
    }
    if (req.method == 'DELETE' && partes[2] == 'students') {
      alunos.remove(Uri.decodeComponent(partes[3]));
      return json(turma);
    }
    return json({'message': 'Rota inesperada'}, 500);
  }
}

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
    await tester.pumpWidget(
      MaterialApp(
        home: TurmasPage(
          nfcService: nfcService,
          api: TurmasApi(
            client: MockClient(backend.handle),
            baseUrl: 'http://api.teste',
            professorId: 'prof1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => backend = FakeBackend());

  testWidgets('Carrega as aulas vindas da API', (tester) async {
    await abrirLista(tester);
    expect(find.text('Minhas aulas'), findsOneWidget);
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

  testWidgets('Avisa quando o professor não está definido', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final api = TurmasApi(
      client: MockClient(backend.handle),
      baseUrl: 'http://api.teste',
      professorId: '',
    );
    await tester.pumpWidget(MaterialApp(home: TurmasPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.textContaining('PROFESSOR_ID'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(FilterChip, '2026.1'));
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
    expect(backend.turmas.any((t) => t['disciplina'] == 'Compiladores'), true);
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
    expect(backend.turmas[1]['disciplina'], 'Banco de Dados II');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Banco de Dados II'), findsOneWidget);
  });

  testWidgets(
    'Abre o fluxo NFC do detalhe e informa quando não está disponível',
    (tester) async {
      await abrirLista(tester, nfcService: _NfcIndisponivel());
      await tester.tap(find.text('Projeto Integrador VI'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('validar-presenca')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'NFC indisponível neste dispositivo. Use um aparelho compatível e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('nfc-tentar-novamente')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cancela a leitura NFC e volta ao detalhe da turma', (
    tester,
  ) async {
    await abrirLista(tester, nfcService: _NfcAguardandoCartao());
    await tester.tap(find.text('Projeto Integrador VI'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validar-presenca')));
    await tester.pumpAndSettle();

    expect(find.text('Aproxime o celular'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nfc-cancelar')));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe da aula'), findsOneWidget);
  });

  testWidgets('Adiciona e remove alunos', (tester) async {
    await abrirLista(tester);
    await tester.tap(find.text('Banco de Dados'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (0)'), findsOneWidget);
    expect(find.text('Nenhum aluno matriculado.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adicionar-aluno')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('aluno-id')), '24099999');
    await tester.tap(find.byKey(const Key('confirmar-aluno')));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (1)'), findsOneWidget);
    expect(find.text('Aluno 24099999'), findsOneWidget);
    expect(backend.turmas[1]['listaAlunos'], ['24099999']);

    await tester.tap(find.byTooltip('Remover 24099999'));
    await tester.pumpAndSettle();
    expect(find.text('Alunos (0)'), findsOneWidget);
    expect(backend.turmas[1]['listaAlunos'], isEmpty);
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
    expect(backend.turmas.length, 2);
  });

  testWidgets('Tela pequena não gera overflow', (tester) async {
    await abrirLista(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
