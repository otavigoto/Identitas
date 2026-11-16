import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'turma.dart';

/// Erro com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Acesso às rotas `/classes` do backend.
class TurmasApi {
  TurmasApi({http.Client? client, String? baseUrl, String? professorId})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _professorId = professorId ?? ApiConfig.professorId;

  final http.Client _client;
  final String _baseUrl;
  final String _professorId;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (ApiConfig.token != null) 'Authorization': 'Bearer ${ApiConfig.token}',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Turma> _turma(Future<http.Response> Function() request) async =>
      Turma.fromJson(await _send(request) as Map<String, dynamic>);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 10));
    } on Exception {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique se o backend está '
        'rodando.',
      );
    }
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body is Map ? body['message'] : null;
    throw ApiException(
      msg is List
          ? msg.join('\n')
          : (msg as String? ?? 'Erro ${res.statusCode} no servidor.'),
    );
  }

  Future<List<Turma>> listar() async {
    if (_professorId.isEmpty) {
      throw const ApiException(
        'Professor não definido. Rode o app com '
        '--dart-define=PROFESSOR_ID=<id do professor>.',
      );
    }
    final data =
        await _send(
              () => _client.get(
                _uri('/classes/teacher/$_professorId'),
                headers: _headers,
              ),
            )
            as List<dynamic>;
    return [for (final t in data) Turma.fromJson(t as Map<String, dynamic>)];
  }

  Future<Turma> criar({
    required String nome,
    required String disciplina,
    required String semestre,
  }) => _turma(
    () => _client.post(
      _uri('/classes'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        'disciplina': disciplina,
        'semestre': semestre,
        'id_professor': _professorId,
      }),
    ),
  );

  Future<Turma> atualizar(
    String id, {
    required String nome,
    required String disciplina,
    required String semestre,
  }) => _turma(
    () => _client.patch(
      _uri('/classes/$id'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        'disciplina': disciplina,
        'semestre': semestre,
      }),
    ),
  );

  Future<void> excluir(String id) =>
      _send(() => _client.delete(_uri('/classes/$id'), headers: _headers));

  Future<Turma> adicionarAluno(String id, String alunoId) => _turma(
    () => _client.post(
      _uri('/classes/$id/students'),
      headers: _headers,
      body: jsonEncode({'alunoId': alunoId}),
    ),
  );

  Future<Turma> removerAluno(String id, String alunoId) => _turma(
    () => _client.delete(
      _uri('/classes/$id/students/${Uri.encodeComponent(alunoId)}'),
      headers: _headers,
    ),
  );
}
