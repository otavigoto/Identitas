import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../login_page.dart';
import '../models/user_profile.dart';
import 'user_profile_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.initialProfile,
    this.token,
    this.baseUrl,
  });

  /// Perfil inicial para exibição imediata (útil em testes ou cache)
  final UserProfile? initialProfile;

  /// Token JWT Bearer. Se omitido, usará [ApiConfig.token].
  final String? token;

  /// URL base do backend. Se omitida, usará 'http://163.176.12.54:3000'.
  final String? baseUrl;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  /// Endereço padrão do backend conforme fornecido pela equipe
  static const String _defaultBackendUrl = 'http://163.176.12.54:3000';

  String get _effectiveBaseUrl =>
      widget.baseUrl ??
      (ApiConfig.baseUrl.contains('163.176.12.54')
          ? ApiConfig.baseUrl
          : _defaultBackendUrl);

  String? get _effectiveToken => widget.token ?? ApiConfig.token;

  static const List<String> _samplePhotos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
    } else {
      _carregarPerfil();
    }
  }

  /// Busca os dados do perfil autenticado através da rota GET /auth/profile
  /// enviando o token JWT no cabeçalho Authorization: Bearer <token>.
  Future<void> _carregarPerfil() async {
    final token = _effectiveToken;

    // Se não houver token configurado, avisamos o usuário e exibimos o modo demonstração
    if (token == null || token.isEmpty) {
      setState(() {
        _profile = UserProfile.mockProfessor();
        _errorMessage =
            'Nenhum token JWT encontrado. Para carregar os dados reais, realize o login.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_effectiveBaseUrl/auth/profile');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          _profile = UserProfile.fromJson(data);
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Sessão expirada ou token inválido (401). Faça login novamente.';
          _profile ??= UserProfile.mockProfessor();
        });
      } else {
        String detalheErro = 'Erro ${response.statusCode} ao carregar perfil.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            detalheErro = body['message'] is List
                ? (body['message'] as List).join('\n')
                : body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _isLoading = false;
          _errorMessage = detalheErro;
          _profile ??= UserProfile.mockProfessor();
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Tempo esgotado ao conectar ao servidor em $_effectiveBaseUrl.';
          _profile ??= UserProfile.mockProfessor();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Não foi possível conectar ao servidor ($_effectiveBaseUrl). Verifique sua conexão.';
          _profile ??= UserProfile.mockProfessor();
        });
      }
    }
  }

  void _abrirModalFoto() {
    final urlController = TextEditingController(text: _profile?.photoUrl ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Alterar Foto de Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha uma foto de exemplo ou cole uma URL de imagem:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final foto in _samplePhotos)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _atualizarFoto(foto);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF9FF2E),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(foto),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'URL da Imagem',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'https://exemplo.com/sua-foto.jpg',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_profile?.photoUrl != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _atualizarFoto(null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Remover Foto'),
                      ),
                    ),
                  if (_profile?.photoUrl != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final novaUrl = urlController.text.trim();
                        Navigator.pop(ctx);
                        _atualizarFoto(novaUrl.isEmpty ? null : novaUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9FF2E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _atualizarFoto(String? novaFotoUrl) {
    if (_profile == null) return;
    setState(() {
      _profile = _profile!.copyWith(
        photoUrl: novaFotoUrl,
        clearPhoto: novaFotoUrl == null,
      );
    });
  }

  void _fazerLogout() {
    ApiConfig.token = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF1E1E1E);
    const accentYellow = Color(0xFFF9FF2E);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: accentYellow),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meu Perfil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade900.withAlpha(60),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      tooltip: 'Tentar novamente',
                                      onPressed: _carregarPerfil,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            UserProfileCard(
                              profile: _profile,
                              onPhotoTap: _abrirModalFoto,
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _fazerLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Sair',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
