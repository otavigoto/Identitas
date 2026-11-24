import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

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
