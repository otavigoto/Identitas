import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registra as requisições e responde conforme [responder].
class _Servidor {
  _Servidor(this.responder);

  final http.Response Function(http.Request req) responder;
  final List<http.Request> pedidos = [];

  Future<http.Response> handle(http.Request req) async {
    pedidos.add(req);
    return responder(req);
  }

  http.Request get ultimo => pedidos.last;
  Map<String, dynamic> get corpo =>
      jsonDecode(ultimo.body) as Map<String, dynamic>;
}

http.Response _json(Object? data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

const _usuarioProfessor = {
  '_id': 'p1',
  'name': 'Prof Teste',
  'ra': '0001',
  'role': 'PROFESSOR',
};

ApiClient _cliente(_Servidor s, {Session? session}) => ApiClient(
  httpClient: MockClient(s.handle),
  baseUrl: 'http://api.teste',
  session: session ?? Session(),
);

Session _logado() => Session()
  ..accessToken = 'velho'
  ..refreshToken = 'refresh'
  ..userId = 'u1'
  ..role = 'STUDENT';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthApi', () {
    test('login envia RA/senha sem token e guarda a sessão', () async {
      final s = _Servidor(
        (_) => _json({
          'user': _usuarioProfessor,
          'accessToken': 'acc',
          'refreshToken': 'ref',
        }),
      );
      final auth = AuthApi(_cliente(s));

      final usuario = await auth.login(' 0001 ', 'senha');

      expect(s.ultimo.method, 'POST');
      expect(s.ultimo.url.path, '/auth');
      expect(s.corpo, {'ra': '0001', 'password': 'senha'});
      expect(s.ultimo.headers.containsKey('Authorization'), isFalse);
      expect(usuario.ehProfessor, isTrue);
      expect(auth.sessao.accessToken, 'acc');
      expect(auth.sessao.userId, 'p1');

      // A sessão foi gravada no aparelho e pode ser restaurada.
      final outra = AuthApi(_cliente(s));
      expect(await outra.restaurarSessao(), isTrue);
      expect(outra.sessao.role, 'PROFESSOR');
      expect(outra.sessao.refreshToken, 'ref');
    });

    test('login inválido mostra a mensagem do backend', () async {
      final s = _Servidor(
        (_) => _json({'message': 'RA ou senha inválidos.'}, 401),
      );
      final auth = AuthApi(_cliente(s));
      await expectLater(
        auth.login('1', 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'RA ou senha inválidos.',
          ),
        ),
      );
      expect(s.pedidos.length, 1, reason: '401 do login não tenta refresh');
    });

    test('logout apaga a sessão local', () async {
      final auth = AuthApi(
        _cliente(_Servidor((_) => _json({})), session: _logado()),
      );
      await auth.sessao.salvar();
      await auth.logout();
      expect(auth.sessao.ativa, isFalse);
      expect(
        await AuthApi(_cliente(_Servidor((_) => _json({})))).restaurarSessao(),
        isFalse,
      );
    });

    test('perfil e vínculo de NFC usam as rotas certas', () async {
      final s = _Servidor((_) => _json(_usuarioProfessor));
      final auth = AuthApi(_cliente(s, session: _logado()));
      await auth.perfil();
      expect(s.ultimo.url.path, '/auth/profile');
      expect(s.ultimo.headers['Authorization'], 'Bearer velho');
      await auth.vincularNfc('u1', 'A1B2');
      expect(s.ultimo.method, 'PATCH');
      expect(s.ultimo.url.path, '/users/u1/nfc');
      expect(s.corpo, {'nfcUid': 'A1B2'});
    });
  });

  group('ApiClient', () {
    test('401 renova o token e repete a requisição uma vez', () async {
      final s = _Servidor((req) {
        if (req.url.path == '/auth/refresh') {
          return _json({'accessToken': 'novo', 'refreshToken': 'ref2'});
        }
        return req.headers['Authorization'] == 'Bearer novo'
            ? _json({'user': _usuarioProfessor, 'classes': []})
            : _json({'message': 'Unauthorized'}, 401);
      });
      final sessao = _logado();
      final aluno = AlunoApi(_cliente(s, session: sessao));

      final hoje = await aluno.aulasDeHoje();

      expect(hoje.aulas, isEmpty);
      expect(s.pedidos.map((p) => p.url.path), [
        '/classes/me/today',
        '/auth/refresh',
        '/classes/me/today',
      ]);
      expect(sessao.accessToken, 'novo');
      expect(sessao.refreshToken, 'ref2');
    });

    test('refresh recusado limpa a sessão e pede novo login', () async {
      final s = _Servidor((req) => _json({'message': 'Unauthorized'}, 401));
      final sessao = _logado();
      final aluno = AlunoApi(_cliente(s, session: sessao));
      await expectLater(
        aluno.aulasDeHoje(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Sessão expirada'),
          ),
        ),
      );
      expect(sessao.accessToken, isNull);
    });

    test('sem conexão não derruba a sessão', () async {
      final sessao = _logado();
      final aluno = AlunoApi(
        ApiClient(
          httpClient: MockClient((_) async => throw http.ClientException('x')),
          baseUrl: 'http://api.teste',
          session: sessao,
        ),
      );
      await expectLater(
        aluno.aulasDeHoje(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Não foi possível conectar'),
          ),
        ),
      );
      expect(sessao.accessToken, 'velho');
    });

    test('junta mensagens de validação em lista', () async {
      final s = _Servidor(
        (_) => _json({
          'message': ['name vazio', 'week vazio'],
        }, 400),
      );
      final turmas = TurmasApi(_cliente(s, session: _logado()));
      await expectLater(
        turmas.listar(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'name vazio\nweek vazio',
          ),
        ),
      );
    });
  });

  group('AlunoApi', () {
    test(
      'aulas de hoje com data, frequência da semana e NFC do professor',
      () async {
        final s = _Servidor((req) {
          if (req.url.path == '/classes/me/weekly') {
            return _json({
              'user': {'id': 'u1', 'name': 'Ana', 'ra': '1', 'role': 'STUDENT'},
              'classes': [
                {
                  'id': 'c1',
                  'name': 'Banco de Dados',
                  'id_professor': 'p1',
                  'week': 'Terça-feira',
                  'startTime': '08:00',
                  'endTime': '09:40',
                  'attendance': {
                    'lessons': 4,
                    'present': 3,
                    'absent': 1,
                    'percentage': 75,
                    'history': [],
                  },
                },
              ],
              'overallAttendance': {
                'lessons': 4,
                'present': 3,
                'absent': 1,
                'percentage': 75,
              },
            });
          }
          if (req.url.path == '/classes/me/today') {
            return _json({
              'user': {'id': 'u1', 'name': 'Ana', 'ra': '1', 'role': 'STUDENT'},
              'classes': [
                {
                  'id': 'c1',
                  'name': 'Banco de Dados',
                  'id_professor': 'p1',
                  'week': 'Terça-feira',
                  'startTime': '08:00',
                  'endTime': '09:40',
                  'attendanceRecorded': true,
                  'present': true,
                },
              ],
            });
          }
          if (req.url.path == '/classes/student/u1') return _json([]);
          return _json({});
        });
        final aluno = AlunoApi(_cliente(s, session: _logado()));

        final hoje = await aluno.aulasDeHoje(data: '2026-11-16');
        expect(s.ultimo.url.queryParameters, {'date': '2026-11-16'});
        expect(hoje.aulas.single.present, isTrue);
        expect(hoje.usuario.name, 'Ana');

        final semana = await aluno.aulasDaSemana();
        expect(semana.geral!.percentage, 75);
        expect(semana.aulas.single.frequencia!.present, 3);
        expect(semana.aulas.single.indiceDoDia, 1);

        await aluno.registrarPresencaProfessor('c1', 'A1B2');
        expect(s.ultimo.method, 'POST');
        expect(s.ultimo.url.path, '/classes/c1/attendance/scan-professor');
        expect(s.corpo, {'nfcUid': 'A1B2'});

        await aluno.minhasTurmas();
        expect(s.ultimo.url.path, '/classes/student/u1');
      },
    );
  });

  group('ProfessorApi', () {
    test('chamada: lista, abrir, enviar completa e por NFC', () async {
      final s = _Servidor((req) {
        if (req.method == 'GET' && req.url.path == '/classes/c1/students') {
          return _json({
            'class': {
              'id': 'c1',
              'name': 'BD',
              'id_professor': 'p1',
              'week': 'Terça-feira',
              'startTime': '08:00',
              'endTime': '09:40',
            },
            'date': '2026-11-23T00:00:00.000Z',
            'attendanceRecorded': false,
            'totalStudents': 1,
            'present': 0,
            'absent': 1,
            'students': [
              {
                'id': 'a1',
                'name': 'Ana',
                'ra': '1',
                'nfcUid': null,
                'present': false,
              },
            ],
          });
        }
        return _json({});
      });
      final prof = ProfessorApi(_cliente(s, session: _logado()));

      final lista = await prof.listaChamada('c1');
      expect(lista.total, 1);
      expect(lista.alunos.single.nfcUid, isNull);

      await prof.abrirChamada('c1');
      expect(s.ultimo.method, 'PATCH');
      expect(s.ultimo.url.path, '/classes/c1/attendance/open');

      await prof.enviarChamada('c1', {'a1': true, 'a2': false});
      expect(s.ultimo.url.path, '/classes/c1/students/attendance');
      expect(s.corpo, {
        'students': [
          {'studentId': 'a1', 'present': true},
          {'studentId': 'a2', 'present': false},
        ],
      });

      await prof.fecharChamada('c1');
      expect(s.ultimo.method, 'PATCH');
      expect(s.ultimo.url.path, '/classes/c1/attendance/close');

      await prof.presencaPorNfc('c1', ['A1B2', 'C3D4']);
      expect(s.ultimo.url.path, '/classes/c1/students/attendance/nfc');
      expect(s.corpo, {
        'nfcUids': ['A1B2', 'C3D4'],
      });
    });
  });

  group('TurmasApi', () {
    test(
      'cria com o contrato do backend e matricula por enrolledStudents',
      () async {
        final s = _Servidor(
          (_) => _json({
            '_id': 't1',
            'name': 'BD',
            'id_professor': 'u1',
            'week': 'Terça-feira',
            'startTime': '08:00',
            'endTime': '09:40',
            'enrolledStudents': ['a1'],
          }),
        );
        final turmas = TurmasApi(_cliente(s, session: _logado()));

        await turmas.criar(
          name: 'BD',
          week: 'Terça-feira',
          startTime: '08:00',
          endTime: '09:40',
        );
        expect(s.ultimo.url.path, '/classes');
        expect(s.corpo, {
          'name': 'BD',
          'id_professor': 'u1',
          'week': 'Terça-feira',
          'startTime': '08:00',
          'endTime': '09:40',
          'attendanceStatus': 'closed',
        });

        final t = await turmas.adicionarAluno('t1', 'a1');
        expect(s.corpo, {
          'enrolledStudents': ['a1'],
        });
        expect(t.enrolledStudents, ['a1']);
      },
    );
  });
}
