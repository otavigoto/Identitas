import 'package:flutter/foundation.dart';

/// Configuração de acesso à API do backend (NestJS + MongoDB).
///
/// Valores por `--dart-define`, por exemplo:
/// `flutter run -d chrome --dart-define=PROFESSOR_ID=<_id do professor>`
class ApiConfig {
  const ApiConfig._();

  static const _url = String.fromEnvironment('API_URL');

  /// `_id` do professor logado. TODO: vir do JWT quando o login existir.
  static const professorId = String.fromEnvironment('PROFESSOR_ID');

  /// TODO: preenchido com o token JWT após o login; enviado como Bearer.
  static String? token;

  static String get baseUrl {
    if (_url.isNotEmpty) return _url;
    // No emulador Android, localhost é o próprio emulador.
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }
}
