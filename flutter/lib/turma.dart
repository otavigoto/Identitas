/// Turma (aula) como o backend expõe em `/classes`.
class Turma {
  const Turma({
    required this.id,
    required this.name,
    required this.idProfessor,
    required this.week,
    required this.startTime,
    required this.endTime,
    this.attendanceStatus = 'closed',
    this.qtdAulas,
    this.enrolledStudents = const [],
  });

  factory Turma.fromJson(Map<String, dynamic> json) => Turma(
    id: (json['_id'] ?? json['id']) as String,
    name: json['name'] as String? ?? '',
    idProfessor: json['id_professor'] as String? ?? '',
    week: json['week'] as String? ?? '',
    startTime: json['startTime'] as String? ?? '',
    endTime: json['endTime'] as String? ?? '',
    attendanceStatus: json['attendanceStatus'] as String? ?? 'closed',
    qtdAulas: (json['qtdAulas'] as num?)?.toInt(),
    enrolledStudents: [
      for (final a in (json['enrolledStudents'] as List<dynamic>? ?? const []))
        a as String,
    ],
  );

  final String id;
  final String name;
  final String idProfessor;

  /// Dia da semana (ex.: `Segunda-feira`).
  final String week;

  /// `HH:mm`.
  final String startTime;
  final String endTime;

  /// `open` ou `closed`.
  final String attendanceStatus;
  final int? qtdAulas;

  /// IDs (MongoDB) dos alunos matriculados.
  final List<String> enrolledStudents;

  String get horario => '$startTime - $endTime';
}
