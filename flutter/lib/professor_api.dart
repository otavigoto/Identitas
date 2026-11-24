import 'api_client.dart';
import 'models.dart';

/// Rotas usadas pelo professor (role `PROFESSOR`): agenda, chamada e
/// cadastro de alunos.
class ProfessorApi {
  ProfessorApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// `GET /classes/me/today`: aulas do dia (sem frequência).
  Future<AulasDoDia> aulasDeHoje({String? data}) async => AulasDoDia.fromJson(
    await _api.get(
          '/classes/me/today',
          query: data == null ? null : {'date': data},
        )
        as Map<String, dynamic>,
  );

  /// `GET /classes/me/weekly`: disciplinas e horários da semana.
  Future<AulasDaSemana> aulasDaSemana() async => AulasDaSemana.fromJson(
    await _api.get('/classes/me/weekly') as Map<String, dynamic>,
  );

  /// `GET /classes/:id/students`: alunos da turma com presença do dia.
  Future<ListaChamada> listaChamada(String turmaId, {String? data}) async =>
      ListaChamada.fromJson(
        await _api.get(
              '/classes/$turmaId/students',
              query: data == null ? null : {'date': data},
            )
            as Map<String, dynamic>,
      );

  /// `GET /classes/:id/students/all`: resumo e histórico de cada aluno.
  Future<Map<String, dynamic>> resumoAlunos(String turmaId) async =>
      await _api.get('/classes/$turmaId/students/all') as Map<String, dynamic>;

  /// `GET /classes/:id/attendance/summary`: frequência geral da turma.
  Future<Map<String, dynamic>> resumoFrequencia(String turmaId) async =>
      await _api.get('/classes/$turmaId/attendance/summary')
          as Map<String, dynamic>;

  /// `PATCH /classes/:id/attendance/open`: abre a chamada por 5 minutos.
  Future<void> abrirChamada(String turmaId) =>
      _api.patch('/classes/$turmaId/attendance/open');

  /// `PATCH /classes/:id/attendance/close`: encerra a chamada da turma.
  Future<void> fecharChamada(String turmaId) =>
      _api.patch('/classes/$turmaId/attendance/close');

  /// `POST /classes/:id/students/attendance`: envia a chamada completa.
  /// [presencas] tem todos os alunos matriculados (`id` → presente?).
  Future<void> enviarChamada(String turmaId, Map<String, bool> presencas) =>
      _api.post(
        '/classes/$turmaId/students/attendance',
        body: {
          'students': [
            for (final e in presencas.entries)
              {'studentId': e.key, 'present': e.value},
          ],
        },
      );

  /// `POST /classes/:id/students/attendance/nfc`: marca presentes os alunos
  /// dos cartões lidos.
  Future<void> presencaPorNfc(String turmaId, List<String> nfcUids) =>
      _api.post(
        '/classes/$turmaId/students/attendance/nfc',
        body: {'nfcUids': nfcUids},
      );

  /// `POST /users`: cadastra um usuário (só professor pode).
  Future<Usuario> cadastrarUsuario({
    required String name,
    required String ra,
    required String course,
    required String periodSemester,
    required String password,
    required String role,
    String? nfcUid,
  }) async => Usuario.fromJson(
    await _api.post(
          '/users',
          body: {
            'name': name,
            'ra': ra,
            'course': course,
            'periodSemester': periodSemester,
            'password': password,
            'role': role,
            'nfcUid': ?nfcUid,
          },
        )
        as Map<String, dynamic>,
  );
}
