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

  final String id;
  final String nome;
  final String disciplina;
  final String semestre;
  final String idProfessor;

  /// RAs dos alunos matriculados.
  final List<String> listaAlunos;

  Turma copyWith({
    String? nome,
    String? disciplina,
    String? semestre,
    List<String>? listaAlunos,
  }) => Turma(
    id: id,
    nome: nome ?? this.nome,
    disciplina: disciplina ?? this.disciplina,
    semestre: semestre ?? this.semestre,
    idProfessor: idProfessor,
    listaAlunos: listaAlunos ?? this.listaAlunos,
  );
}

class Aluno {
  const Aluno({required this.ra, required this.nome});

  final String ra;
  final String nome;
}
