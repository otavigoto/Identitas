import 'package:flutter/material.dart';

import '../api_config.dart';
import '../login_page.dart';
import '../models/user_profile.dart';
import '../profile_api.dart';
import 'user_profile_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.initialProfile});

  final UserProfile? initialProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileApi _profileApi;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _samplePhotos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
  ];

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi();

    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
    } else {
      _carregarPerfil();
    }
  }

  Future<void> _carregarPerfil() async {
    if (ApiConfig.currentUser != null) {
      setState(() {
        _profile = ApiConfig.currentUser;
      });
      return;
    }

    if (ApiConfig.token != null && ApiConfig.token!.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final perfilCarregado = await _profileApi.obterPerfil();
        if (mounted) {
          setState(() {
            _profile = perfilCarregado;
            ApiConfig.currentUser = perfilCarregado;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }

    setState(() {
      _profile = UserProfile.mockProfessor();
    });
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
    ApiConfig.currentUser = null;
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
                                    const Expanded(
                                      child: Text(
                                        'Exibindo dados locais (modo demonstração).',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
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
