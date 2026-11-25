import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// ===== api_config =====
/// Configuração de acesso à API do backend (NestJS + MongoDB).
///
/// Para apontar para outro servidor use `--dart-define`, por exemplo:
/// `flutter run --dart-define=API_URL=http://163.176.12.54:3000`
///
/// O login e o token ficam em `Session` (`api_client.dart`).
class ApiConfig {
  const ApiConfig._();

  static const _url = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_url.isNotEmpty) return _url;
    return 'http://163.176.12.54:3000';
  }
}

// ===== api_client =====



/// Erro com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// Null quando a falha foi de conexão (sem resposta do servidor).
  final int? statusCode;

  @override
  String toString() => message;
}

/// Sessão do usuário logado: tokens JWT e dados básicos, guardados no
/// aparelho para o login sobreviver ao fechamento do app.
class Session {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kRole = 'user_role';
  static const _kName = 'user_name';

  String? accessToken;
  String? refreshToken;
  String? userId;

  /// `STUDENT` ou `PROFESSOR`.
  String? role;
  String? name;

  bool get ativa => accessToken != null && userId != null;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kAccess);
    refreshToken = prefs.getString(_kRefresh);
    userId = prefs.getString(_kUserId);
    role = prefs.getString(_kRole);
    name = prefs.getString(_kName);
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> grava(String chave, String? valor) async {
      if (valor == null) {
        await prefs.remove(chave);
      } else {
        await prefs.setString(chave, valor);
      }
    }

    await grava(_kAccess, accessToken);
    await grava(_kRefresh, refreshToken);
    await grava(_kUserId, userId);
    await grava(_kRole, role);
    await grava(_kName, name);
  }

  Future<void> limpar() async {
    accessToken = refreshToken = userId = role = name = null;
    await salvar();
  }
}

/// Núcleo HTTP compartilhado pelos módulos (`AuthApi`, `TurmasApi`,
/// `AlunoApi`, `ProfessorApi`): URL base, header Bearer, timeout, mensagens
/// de erro do backend e renovação automática do access token (que expira em
/// 15 minutos) via `POST /auth/refresh`.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, Session? session})
    : _http = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl,
      session = session ?? Session();

  /// Instância usada pelo app. Os testes criam a sua própria.
  static final ApiClient instance = ApiClient();

  final http.Client _http;
  final String baseUrl;
  final Session session;

  Future<bool>? _renovando;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _enviar('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool autenticado = true}) =>
      _enviar('POST', path, body: body, autenticado: autenticado);

  Future<dynamic> patch(String path, {Object? body}) =>
      _enviar('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _enviar('DELETE', path);

  Future<dynamic> _enviar(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool autenticado = true,
    bool podeRenovar = true,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final req = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    final token = session.accessToken;
    if (autenticado && token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) req.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 10)),
      );
    } on Exception {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique se o backend está '
        'rodando.',
      );
    }

    if (res.statusCode == 401 &&
        autenticado &&
        podeRenovar &&
        session.refreshToken != null) {
      if (await _renovar()) {
        return _enviar(
          method,
          path,
          body: body,
          query: query,
          podeRenovar: false,
        );
      }
      await session.limpar();
      throw const ApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );
    }
    return _tratar(res);
  }

  dynamic _tratar(http.Response res) {
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } on FormatException {
        body = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body is Map ? body['message'] : null;
    throw ApiException(
      msg is List
          ? msg.join('\n')
          : (msg as String? ?? 'Erro ${res.statusCode} no servidor.'),
      statusCode: res.statusCode,
    );
  }

  /// Renova o access token com o refresh token. False se não der (sessão
  /// vencida); usado também por serviços que fazem suas próprias requisições.
  Future<bool> renovarSessao() => _renovar();

  Future<bool> _renovar() =>
      _renovando ??= _fazerRenovacao().whenComplete(() => _renovando = null);

  Future<bool> _fazerRenovacao() async {
    try {
      final data =
          await _enviar(
                'POST',
                '/auth/refresh',
                body: {'refreshToken': session.refreshToken},
                autenticado: false,
                podeRenovar: false,
              )
              as Map<String, dynamic>;
      session.accessToken = data['accessToken'] as String;
      session.refreshToken = data['refreshToken'] as String;
      await session.salvar();
      return true;
    } on ApiException catch (e) {
      // Sem conexão não é motivo para deslogar o usuário.
      if (e.statusCode == null) rethrow;
      return false;
    }
  }
}

// ===== auth_api =====

/// Autenticação e conta do usuário: `/auth/*` e vínculo de NFC.
class AuthApi {
  AuthApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Session get sessao => _api.session;

  /// `POST /auth`: entra com RA e senha, guarda os tokens e devolve o usuário.
  Future<Usuario> login(String ra, String senha) async {
    final data =
        await _api.post(
              '/auth',
              body: {'ra': ra.trim(), 'password': senha},
              autenticado: false,
            )
            as Map<String, dynamic>;
    final usuario = Usuario.fromJson(data['user'] as Map<String, dynamic>);
    await _guardar(data, usuario);
    return usuario;
  }

  /// Carrega a sessão salva no aparelho. True se já existe um login.
  Future<bool> restaurarSessao() async {
    await sessao.carregar();
    return sessao.ativa;
  }

  /// Apaga a sessão local (o backend não guarda estado de sessão).
  Future<void> logout() => sessao.limpar();

  /// `GET /auth/profile`: perfil de quem está logado.
  Future<Usuario> perfil() async =>
      Usuario.fromJson(await _api.get('/auth/profile') as Map<String, dynamic>);

  /// `PATCH /auth/update`: altera RA e/ou senha. Trocar a senha exige
  /// [senhaAtual]. O backend devolve novos tokens, que substituem os antigos.
  Future<Usuario> atualizar({
    String? ra,
    String? novaSenha,
    String? senhaAtual,
  }) async {
    final data =
        await _api.patch(
              '/auth/update',
              body: {
                'ra': ?ra,
                'password': ?novaSenha,
                'currentPassword': ?senhaAtual,
              },
            )
            as Map<String, dynamic>;
    final usuario = Usuario.fromJson(data['user'] as Map<String, dynamic>);
    await _guardar(data, usuario);
    return usuario;
  }

  /// `PATCH /users/:id/nfc`: vincula um cartão NFC ao usuário.
  Future<Usuario> vincularNfc(String userId, String nfcUid) async =>
      Usuario.fromJson(
        await _api.patch('/users/$userId/nfc', body: {'nfcUid': nfcUid})
            as Map<String, dynamic>,
      );

  Future<void> _guardar(Map<String, dynamic> data, Usuario usuario) {
    sessao
      ..accessToken = data['accessToken'] as String
      ..refreshToken = data['refreshToken'] as String
      ..userId = usuario.id
      ..role = usuario.role
      ..name = usuario.name;
    return sessao.salvar();
  }
}

// ===== aluno_api =====

/// Rotas usadas pelo aluno (role `STUDENT`).
class AlunoApi {
  AlunoApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// `GET /classes/me/today`: aulas do dia com a presença do aluno.
  /// [data] no formato `AAAA-MM-DD` consulta outro dia.
  Future<AulasDoDia> aulasDeHoje({String? data}) async => AulasDoDia.fromJson(
    await _api.get(
          '/classes/me/today',
          query: data == null ? null : {'date': data},
        )
        as Map<String, dynamic>,
  );

  /// `GET /classes/me/weekly`: aulas da semana com frequência por disciplina
  /// e frequência geral.
  Future<AulasDaSemana> aulasDaSemana() async => AulasDaSemana.fromJson(
    await _api.get('/classes/me/weekly') as Map<String, dynamic>,
  );

  /// `GET /classes/student/:id`: turmas em que o aluno logado está matriculado.
  Future<List<Turma>> minhasTurmas() async {
    final id = _api.session.userId;
    if (id == null) {
      throw const ApiException('Faça login para continuar.');
    }
    final data = await _api.get('/classes/student/$id') as List<dynamic>;
    return [for (final t in data) Turma.fromJson(t as Map<String, dynamic>)];
  }

  /// `POST /classes/:id/attendance/scan-professor`: o aluno encosta o celular
  /// no cartão do professor para registrar a própria presença.
  Future<void> registrarPresencaProfessor(String turmaId, String nfcUid) =>
      _api.post(
        '/classes/$turmaId/attendance/scan-professor',
        body: {'nfcUid': nfcUid},
      );
}

// ===== professor_api =====

/// Rotas usadas pelo professor (role `PROFESSOR`): agenda, chamada e
/// cadastro de alunos.
class ProfessorApi {
  ProfessorApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// `GET /classes/me/today`: aulas do dia (sem frequência).
  Future<AulasDoDia> aulasDeHoje({String? data}) async => AulasDoDia.fromJson(
    await _api.get(
          '/classes/me/today',
          query: data == null ? null : {'date': data},
        )
        as Map<String, dynamic>,
  );

  /// `GET /classes/me/weekly`: disciplinas e horários da semana.
  Future<AulasDaSemana> aulasDaSemana() async => AulasDaSemana.fromJson(
    await _api.get('/classes/me/weekly') as Map<String, dynamic>,
  );

  /// `GET /classes/:id/students`: alunos da turma com presença do dia.
  Future<ListaChamada> listaChamada(String turmaId, {String? data}) async =>
      ListaChamada.fromJson(
        await _api.get(
              '/classes/$turmaId/students',
              query: data == null ? null : {'date': data},
            )
            as Map<String, dynamic>,
      );

  /// `GET /classes/:id/students/all`: resumo e histórico de cada aluno.
  Future<Map<String, dynamic>> resumoAlunos(String turmaId) async =>
      await _api.get('/classes/$turmaId/students/all') as Map<String, dynamic>;

  /// `GET /classes/:id/attendance/summary`: frequência geral da turma.
  Future<Map<String, dynamic>> resumoFrequencia(String turmaId) async =>
      await _api.get('/classes/$turmaId/attendance/summary')
          as Map<String, dynamic>;

  /// `PATCH /classes/:id/attendance/open`: abre a chamada por 5 minutos.
  Future<void> abrirChamada(String turmaId) =>
      _api.patch('/classes/$turmaId/attendance/open');

  /// `PATCH /classes/:id/attendance/close`: encerra a chamada da turma.
  Future<void> fecharChamada(String turmaId) =>
      _api.patch('/classes/$turmaId/attendance/close');

  /// `POST /classes/:id/students/attendance`: envia a chamada completa.
  /// [presencas] tem todos os alunos matriculados (`id` → presente?).
  Future<void> enviarChamada(String turmaId, Map<String, bool> presencas) =>
      _api.post(
        '/classes/$turmaId/students/attendance',
        body: {
          'students': [
            for (final e in presencas.entries)
              {'studentId': e.key, 'present': e.value},
          ],
        },
      );

  /// `POST /classes/:id/students/attendance/nfc`: marca presentes os alunos
  /// dos cartões lidos.
  Future<void> presencaPorNfc(String turmaId, List<String> nfcUids) =>
      _api.post(
        '/classes/$turmaId/students/attendance/nfc',
        body: {'nfcUids': nfcUids},
      );

  /// `POST /users`: cadastra um usuário (só professor pode).
  Future<Usuario> cadastrarUsuario({
    required String name,
    required String ra,
    required String course,
    required String periodSemester,
    required String password,
    required String role,
    String? nfcUid,
  }) async => Usuario.fromJson(
    await _api.post(
          '/users',
          body: {
            'name': name,
            'ra': ra,
            'course': course,
            'periodSemester': periodSemester,
            'password': password,
            'role': role,
            'nfcUid': ?nfcUid,
          },
        )
        as Map<String, dynamic>,
  );
}

// ===== turmas_api =====

// `ApiException` mora em `api_client.dart`; reexportada para quem já importa
// este arquivo.

/// CRUD de turmas (`/classes`) e matrícula de alunos.
class TurmasApi {
  TurmasApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  String get _professorId {
    final id = _api.session.userId;
    if (id == null) throw const ApiException('Faça login para continuar.');
    return id;
  }

  Turma _turma(dynamic json) => Turma.fromJson(json as Map<String, dynamic>);

  /// `GET /classes/teacher/:id`: turmas do professor logado.
  Future<List<Turma>> listar() async {
    final data =
        await _api.get('/classes/teacher/$_professorId') as List<dynamic>;
    return [for (final t in data) _turma(t)];
  }

  /// `GET /classes/:id`.
  Future<Turma> buscar(String id) async =>
      _turma(await _api.get('/classes/$id'));

  /// `POST /classes`. A chamada nasce fechada e o professor é o logado.
  Future<Turma> criar({
    required String name,
    required String week,
    required String startTime,
    required String endTime,
  }) async => _turma(
    await _api.post(
      '/classes',
      body: {
        'name': name,
        'id_professor': _professorId,
        'week': week,
        'startTime': startTime,
        'endTime': endTime,
        'attendanceStatus': 'closed',
      },
    ),
  );

  /// `PATCH /classes/:id`.
  Future<Turma> atualizar(
    String id, {
    required String name,
    required String week,
    required String startTime,
    required String endTime,
  }) async => _turma(
    await _api.patch(
      '/classes/$id',
      body: {
        'name': name,
        'week': week,
        'startTime': startTime,
        'endTime': endTime,
      },
    ),
  );

  /// `DELETE /classes/:id`.
  Future<void> excluir(String id) => _api.delete('/classes/$id');

  /// `POST /classes/:id/students`: [alunoId] é o ID MongoDB do aluno.
  Future<Turma> adicionarAluno(String id, String alunoId) async => _turma(
    await _api.post(
      '/classes/$id/students',
      body: {
        'enrolledStudents': [alunoId],
      },
    ),
  );

  /// `DELETE /classes/:id/students/:studentId`.
  Future<Turma> removerAluno(String id, String alunoId) async => _turma(
    await _api.delete('/classes/$id/students/${Uri.encodeComponent(alunoId)}'),
  );
}

