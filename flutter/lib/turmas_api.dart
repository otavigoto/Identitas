import 'api_client.dart';
import 'turma.dart';

// `ApiException` mora em `api_client.dart`; reexportada para quem já importa
// este arquivo.
export 'api_client.dart' show ApiException;

/// CRUD de turmas (`/classes`) e matrícula de alunos.
class TurmasApi {
  TurmasApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  String get _professorId {
    final id = _api.session.userId;
    if (id == null) throw const ApiException('Faça login para continuar.');
    return id;
  }

  Turma _turma(dynamic json) => Turma.fromJson(json as Map<String, dynamic>);

  /// `GET /classes/teacher/:id`: turmas do professor logado.
  Future<List<Turma>> listar() async {
    final data =
        await _api.get('/classes/teacher/$_professorId') as List<dynamic>;
    return [for (final t in data) _turma(t)];
  }

  /// `GET /classes/:id`.
  Future<Turma> buscar(String id) async =>
      _turma(await _api.get('/classes/$id'));

  /// `POST /classes`. A chamada nasce fechada e o professor é o logado.
  Future<Turma> criar({
    required String name,
    required String week,
    required String startTime,
    required String endTime,
  }) async => _turma(
    await _api.post(
      '/classes',
      body: {
        'name': name,
        'id_professor': _professorId,
        'week': week,
        'startTime': startTime,
        'endTime': endTime,
        'attendanceStatus': 'closed',
      },
    ),
  );

  /// `PATCH /classes/:id`.
  Future<Turma> atualizar(
    String id, {
    required String name,
    required String week,
    required String startTime,
    required String endTime,
  }) async => _turma(
    await _api.patch(
      '/classes/$id',
      body: {
        'name': name,
        'week': week,
        'startTime': startTime,
        'endTime': endTime,
      },
    ),
  );

  /// `DELETE /classes/:id`.
  Future<void> excluir(String id) => _api.delete('/classes/$id');

  /// `POST /classes/:id/students`: [alunoId] é o ID MongoDB do aluno.
  Future<Turma> adicionarAluno(String id, String alunoId) async => _turma(
    await _api.post(
      '/classes/$id/students',
      body: {
        'enrolledStudents': [alunoId],
      },
    ),
  );

  /// `DELETE /classes/:id/students/:studentId`.
  Future<Turma> removerAluno(String id, String alunoId) async => _turma(
    await _api.delete('/classes/$id/students/${Uri.encodeComponent(alunoId)}'),
  );
}
