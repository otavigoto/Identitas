import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'models/user_profile.dart';
import 'turmas_api.dart';

class ProfileApi {
  ProfileApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (ApiConfig.token != null) 'Authorization': 'Bearer ${ApiConfig.token}',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<UserProfile> obterPerfil() async {
    if (ApiConfig.token == null || ApiConfig.token!.isEmpty) {
      throw const ApiException(
        'Nenhum usuário autenticado. Faça login ou use o modo demonstração.',
      );
    }

    final http.Response res;
    try {
      res = await _client
          .get(_uri('/auth/profile'), headers: _headers)
          .timeout(const Duration(seconds: 10));
    } on Exception {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique se o backend está rodando.',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return UserProfile.fromJson(body);
    }

    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    final msg = body is Map ? body['message'] : null;
    throw ApiException(
      msg is List
          ? msg.join('\n')
          : (msg as String? ?? 'Erro ${res.statusCode} ao carregar perfil.'),
    );
  }
}
