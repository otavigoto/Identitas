import 'api_client.dart';
import 'models.dart';
import 'turma.dart';

/// Rotas usadas pelo aluno (role `STUDENT`).
class AlunoApi {
  AlunoApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// `GET /classes/me/today`: aulas do dia com a presença do aluno.
  /// [data] no formato `AAAA-MM-DD` consulta outro dia.
  Future<AulasDoDia> aulasDeHoje({String? data}) async => AulasDoDia.fromJson(
    await _api.get(
          '/classes/me/today',
          query: data == null ? null : {'date': data},
        )
        as Map<String, dynamic>,
  );

  /// `GET /classes/me/weekly`: aulas da semana com frequência por disciplina
  /// e frequência geral.
  Future<AulasDaSemana> aulasDaSemana() async => AulasDaSemana.fromJson(
    await _api.get('/classes/me/weekly') as Map<String, dynamic>,
  );

  /// `GET /classes/student/:id`: turmas em que o aluno logado está matriculado.
  Future<List<Turma>> minhasTurmas() async {
    final id = _api.session.userId;
    if (id == null) {
      throw const ApiException('Faça login para continuar.');
    }
    final data = await _api.get('/classes/student/$id') as List<dynamic>;
    return [for (final t in data) Turma.fromJson(t as Map<String, dynamic>)];
  }

  /// `POST /classes/:id/attendance/scan-professor`: o aluno encosta o celular
  /// no cartão do professor para registrar a própria presença.
  Future<void> registrarPresencaProfessor(String turmaId, String nfcUid) =>
      _api.post(
        '/classes/$turmaId/attendance/scan-professor',
        body: {'nfcUid': nfcUid},
      );
}
