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
