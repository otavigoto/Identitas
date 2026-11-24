import 'package:flutter/foundation.dart';

/// Configuração de acesso à API do backend (NestJS + MongoDB).
///
/// Para apontar para outro servidor use `--dart-define`, por exemplo:
/// `flutter run --dart-define=API_URL=http://192.168.0.10:3000`
///
/// O login e o token ficam em `Session` (`api_client.dart`).
class ApiConfig {
  const ApiConfig._();

  static const _url = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_url.isNotEmpty) return _url;
    // No emulador Android, localhost é o próprio emulador.
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }
}
