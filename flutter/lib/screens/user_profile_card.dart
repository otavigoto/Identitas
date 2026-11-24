import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user_profile.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    super.key,
    this.profile,
    this.name,
    this.role,
    this.registration,
    this.institutionUnit,
    this.period,
    this.photoUrl,
    this.onPhotoTap,
  });

  final UserProfile? profile;
  final String? name;
  final String? role;
  final String? registration;
  final String? institutionUnit;
  final String? period;
  final String? photoUrl;
  final VoidCallback? onPhotoTap;

  static const Color _accent = Color(0xFFF9FF2E);
  static const Color _cream = Color(0xFFFEFFD9);
  static const Color _ink = Color(0xFF1E1E1E);
  static const Color _mutedText = Color(0xFF6B6B6B);

  bool get _isProfessor {
    if (profile != null) return profile!.isProfessor;
    final r = (role ?? '').toUpperCase();
    return r.contains('PROF');
  }

  String get _displayName => profile?.name ?? name ?? 'Usuário';

  String get _displayRoleLabel =>
      profile?.role.label ?? (_isProfessor ? 'Professor' : 'Aluno');

  String get _displayRegistration =>
      profile?.registration ??
      registration ??
      (_isProfessor ? '19206582' : '24012345');

  String get _displayInstitutionUnit =>
      profile?.institutionUnit ??
      institutionUnit ??
      (_isProfessor ? 'Escola Politécnica' : 'Sistemas de Informação');

  String? get _displayPeriod =>
      profile?.period ?? period ?? (_isProfessor ? null : '6o semestre');

  String? get _displayPhotoUrl => profile?.photoUrl ?? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPhotoTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: _cream,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildAvatarContent(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _ink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _displayRoleLabel,
                    style: const TextStyle(
                      color: _cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: _cream,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: _isProfessor ? 'RP (Registro do Professor)' : 'RA',
                  value: _displayRegistration,
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: _isProfessor ? 'Escola' : 'Curso',
                  value: _displayInstitutionUnit,
                ),
                if (!_isProfessor && _displayPeriod != null) ...[
                  const SizedBox(height: 18),
                  _buildField(
                    label: 'Período',
                    value: _displayPeriod!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_displayPhotoUrl != null && _displayPhotoUrl!.isNotEmpty) {
      if (_displayPhotoUrl!.startsWith('http')) {
        return Image.network(
          _displayPhotoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(),
        );
      } else {
        return Image.asset(
          _displayPhotoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(),
        );
      }
    }
    return _defaultAvatarIcon();
  }

  Widget _defaultAvatarIcon() {
    return Center(
      child: SvgPicture.asset(
        'assets/icons/figma-user.svg',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _mutedText,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
