// Modelos das respostas do backend usadas por `AuthApi`, `AlunoApi` e
// `ProfessorApi`. Os campos seguem `backend/API_ROUTES.md`.

/// Usuário (aluno ou professor). Aceita `_id` (documento do Mongo) e `id`
/// (respostas montadas pelo backend).
class Usuario {
  const Usuario({
    required this.id,
    required this.name,
    required this.ra,
    required this.role,
    this.course = '',
    this.periodSemester = '',
    this.nfcUid,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: (json['_id'] ?? json['id']) as String,
    name: json['name'] as String? ?? '',
    ra: json['ra'] as String? ?? '',
    role: json['role'] as String? ?? '',
    course: json['course'] as String? ?? '',
    periodSemester: json['periodSemester']?.toString() ?? '',
    nfcUid: json['nfcUid'] as String?,
  );

  final String id;
  final String name;
  final String ra;

  /// `STUDENT` ou `PROFESSOR`.
  final String role;
  final String course;
  final String periodSemester;
  final String? nfcUid;

  bool get ehProfessor => role == 'PROFESSOR';

  /// Mesmo que [ehProfessor]; nome usado pelas telas de `screens/`.
  bool get isProfessor => ehProfessor;
}

/// Frequência de um aluno (em uma disciplina ou geral).
class Frequencia {
  const Frequencia({
    required this.lessons,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory Frequencia.fromJson(Map<String, dynamic> json) => Frequencia(
    lessons: (json['lessons'] as num?)?.toInt() ?? 0,
    present: (json['present'] as num?)?.toInt() ?? 0,
    absent: (json['absent'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
  );

  final int lessons;
  final int present;
  final int absent;

  /// 0 a 100.
  final double percentage;
}

/// Aula/disciplina com horário. Para o aluno, vem com a presença do dia
/// ([attendanceRecorded] e [present]) ou com a [frequencia] da semana.
class Aula {
  const Aula({
    required this.id,
    required this.name,
    required this.idProfessor,
    required this.week,
    required this.startTime,
    required this.endTime,
    this.qtdAulas,
    this.attendanceRecorded = false,
    this.present = false,
    this.frequencia,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'];
    return Aula(
      id: (json['id'] ?? json['_id']) as String,
      name: json['name'] as String? ?? '',
      idProfessor: json['id_professor'] as String? ?? '',
      week: json['week'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      qtdAulas: (json['qtdAulas'] as num?)?.toInt(),
      attendanceRecorded: json['attendanceRecorded'] as bool? ?? false,
      present: json['present'] as bool? ?? false,
      frequencia: att is Map<String, dynamic> ? Frequencia.fromJson(att) : null,
    );
  }

  final String id;
  final String name;
  final String idProfessor;

  /// Dia da semana, como cadastrado (ex.: `Segunda-feira`).
  final String week;
  final String startTime;
  final String endTime;
  final int? qtdAulas;
  final bool attendanceRecorded;
  final bool present;
  final Frequencia? frequencia;

  String get horario => '$startTime - $endTime';

  /// Minutos desde 00:00 para `HH:mm`; null se o formato for inválido.
  static int? minutos(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    return h == null || m == null ? null : h * 60 + m;
  }

  int? get inicioEmMinutos => minutos(startTime);
  int? get fimEmMinutos => minutos(endTime);

  /// Índice do dia (0 = segunda … 6 = domingo) a partir de [week]; -1 se não
  /// reconhecer.
  int get indiceDoDia {
    const prefixos = [
      'segunda',
      'terca',
      'quarta',
      'quinta',
      'sexta',
      'sabado',
      'domingo',
    ];
    final w = week
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a');
    return prefixos.indexWhere(w.startsWith);
  }
}

/// Resposta de `GET /classes/me/today`.
class AulasDoDia {
  const AulasDoDia({required this.usuario, required this.aulas});

  factory AulasDoDia.fromJson(Map<String, dynamic> json) => AulasDoDia(
    usuario: Usuario.fromJson(json['user'] as Map<String, dynamic>),
    aulas: [
      for (final a in (json['classes'] as List<dynamic>? ?? const []))
        Aula.fromJson(a as Map<String, dynamic>),
    ],
  );

  final Usuario usuario;
  final List<Aula> aulas;
}

/// Resposta de `GET /classes/me/weekly`. [geral] só vem para o aluno.
class AulasDaSemana {
  const AulasDaSemana({required this.usuario, required this.aulas, this.geral});

  factory AulasDaSemana.fromJson(Map<String, dynamic> json) {
    final geral = json['overallAttendance'];
    return AulasDaSemana(
      usuario: Usuario.fromJson(json['user'] as Map<String, dynamic>),
      aulas: [
        for (final a in (json['classes'] as List<dynamic>? ?? const []))
          Aula.fromJson(a as Map<String, dynamic>),
      ],
      geral: geral is Map<String, dynamic> ? Frequencia.fromJson(geral) : null,
    );
  }

  final Usuario usuario;
  final List<Aula> aulas;
  final Frequencia? geral;
}

/// Aluno na lista de chamada do professor.
class AlunoChamada {
  const AlunoChamada({
    required this.id,
    required this.name,
    required this.ra,
    required this.present,
    this.nfcUid,
    this.frequencia,
  });

  factory AlunoChamada.fromJson(Map<String, dynamic> json) {
    final attendance = json['attendance'];
    return AlunoChamada(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ra: json['ra'] as String? ?? '',
      present: json['present'] as bool? ?? false,
      nfcUid: json['nfcUid'] as String?,
      frequencia: attendance is Map<String, dynamic>
          ? Frequencia.fromJson(attendance)
          : null,
    );
  }

  final String id;
  final String name;
  final String ra;
  final bool present;
  final String? nfcUid;
  final Frequencia? frequencia;
}

/// Resposta de `GET /classes/:id/students`.
class ListaChamada {
  const ListaChamada({
    required this.aula,
    required this.attendanceRecorded,
    required this.total,
    required this.present,
    required this.absent,
    required this.alunos,
    this.ausentes = const [],
  });

  factory ListaChamada.fromJson(Map<String, dynamic> json) => ListaChamada(
    ausentes: [
      for (final m in (json['missingStudents'] as List<dynamic>? ?? const []))
        (m as Map<String, dynamic>)['id'] as String,
    ],
    aula: Aula.fromJson(json['class'] as Map<String, dynamic>),
    attendanceRecorded: json['attendanceRecorded'] as bool? ?? false,
    total: (json['totalStudents'] as num?)?.toInt() ?? 0,
    present: (json['present'] as num?)?.toInt() ?? 0,
    absent: (json['absent'] as num?)?.toInt() ?? 0,
    alunos: [
      for (final a in (json['students'] as List<dynamic>? ?? const []))
        AlunoChamada.fromJson(a as Map<String, dynamic>),
    ],
  );

  final Aula aula;
  final bool attendanceRecorded;
  final int total;
  final int present;
  final int absent;
  final List<AlunoChamada> alunos;

  /// IDs de matriculados que não existem mais como usuário.
  final List<String> ausentes;
}
