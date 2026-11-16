/// Turma (aula) como o backend expõe em `/classes`.
class Turma {
  const Turma({
    required this.id,
    required this.nome,
    required this.disciplina,
    required this.semestre,
    required this.idProfessor,
    this.listaAlunos = const [],
  });

  factory Turma.fromJson(Map<String, dynamic> json) => Turma(
    id: json['_id'] as String,
    nome: json['nome'] as String,
    disciplina: json['disciplina'] as String,
    semestre: json['semestre'] as String,
    idProfessor: json['id_professor'] as String,
    listaAlunos: [
      for (final a in (json['listaAlunos'] as List<dynamic>? ?? const []))
        a as String,
    ],
  );

  final String id;
  final String nome;
  final String disciplina;
  final String semestre;
  final String idProfessor;

  /// Identificadores dos alunos matriculados (como guardados no MongoDB).
  final List<String> listaAlunos;
}
