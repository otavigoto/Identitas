enum UserRole {
  student,
  professor;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.student;
    final normalized = role.toUpperCase().trim();
    if (normalized == 'PROFESSOR' || normalized == 'PROF') {
      return UserRole.professor;
    }
    return UserRole.student;
  }

  String get label => this == UserRole.professor ? 'Professor' : 'Aluno';
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.registration,
    required this.institutionUnit,
    this.period,
    this.photoUrl,
    this.nfcUid,
  });

  final String id;
  final String name;
  final UserRole role;
  final String registration;
  final String institutionUnit;
  final String? period;
  final String? photoUrl;
  final String? nfcUid;

  bool get isProfessor => role == UserRole.professor;
  bool get isStudent => role == UserRole.student;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromString(json['role'] as String?);
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuário',
      role: role,
      registration: json['ra'] as String? ?? '',
      institutionUnit: json['course'] as String? ?? '',
      period: role == UserRole.student
          ? (json['periodSemester'] as String?)
          : null,
      photoUrl: json['photoUrl'] as String?,
      nfcUid: json['nfcUid'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'role': role == UserRole.professor ? 'PROFESSOR' : 'STUDENT',
    'ra': registration,
    'course': institutionUnit,
    if (period != null) 'periodSemester': period,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (nfcUid != null) 'nfcUid': nfcUid,
  };

  UserProfile copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? registration,
    String? institutionUnit,
    String? period,
    String? photoUrl,
    String? nfcUid,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      registration: registration ?? this.registration,
      institutionUnit: institutionUnit ?? this.institutionUnit,
      period: period ?? this.period,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      nfcUid: nfcUid ?? this.nfcUid,
    );
  }

  factory UserProfile.mockStudent() => const UserProfile(
    id: 'mock_student_pilar',
    name: 'Pilar Brandão',
    role: UserRole.student,
    registration: '24012345',
    institutionUnit: 'Sistemas de Informação',
    period: '6o semestre',
  );

  factory UserProfile.mockProfessor() => const UserProfile(
    id: 'mock_prof_andre',
    name: 'André Maligno',
    role: UserRole.professor,
    registration: '19206582',
    institutionUnit: 'Escola Politécnica',
  );
}
