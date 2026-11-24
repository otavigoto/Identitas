import 'api_client.dart';
import 'models.dart';

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
