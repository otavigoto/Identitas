import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'auth_service.dart';

class AttendanceException implements Exception {
  const AttendanceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AulaIdentitas {
  const AulaIdentitas({
    required this.id,
    required this.name,
    required this.idProfessor,
    required this.week,
    required this.startTime,
    required this.endTime,
    required this.enrolledStudents,
    required this.attendanceStatus,
    this.attendanceList = const [],
  });

  factory AulaIdentitas.fromJson(Map<String, dynamic> json) {
    return AulaIdentitas(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['disciplina'] ?? '').toString(),
      idProfessor: (json['id_professor'] ?? '').toString(),
      week: (json['week'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      enrolledStudents: [
        for (final id in json['enrolledStudents'] as List<dynamic>? ?? const [])
          id.toString(),
      ],
      attendanceStatus: (json['attendanceStatus'] ?? 'closed').toString(),
      attendanceList: [
        for (final item in json['attendanceList'] as List<dynamic>? ?? const [])
          AttendanceItem.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final String idProfessor;
  final String week;
  final String startTime;
  final String endTime;
  final List<String> enrolledStudents;
  final String attendanceStatus;
  final List<AttendanceItem> attendanceList;
}

class AttendanceItem {
  const AttendanceItem({
    required this.date,
    required this.students,
  });

  factory AttendanceItem.fromJson(Map<String, dynamic> json) {
    return AttendanceItem(
      date: DateTime.parse(json['date'].toString()),
      students: [
        for (final student
            in json['students'] as List<dynamic>? ?? const [])
          AttendanceStudent.fromJson(student as Map<String, dynamic>),
      ],
    );
  }

  final DateTime date;
  final List<AttendanceStudent> students;
}

class AttendanceStudent {
  const AttendanceStudent({
    required this.studentId,
    required this.present,
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceStudent(
      studentId: json['studentId'].toString(),
      present: json['present'] == true,
    );
  }

  final String studentId;
  final bool present;
}

class StudentIdentitas {
  const StudentIdentitas({
    required this.id,
    required this.name,
    required this.ra,
  });

  factory StudentIdentitas.fromJson(Map<String, dynamic> json) {
    return StudentIdentitas(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ra: (json['ra'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String ra;
}

class AttendanceService {
  AttendanceService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (ApiConfig.token != null)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String>) request,
  ) async {
    http.Response response;
    try {
      response = await request(_headers).timeout(const Duration(seconds: 10));
    } on Exception {
      throw const AttendanceException(
        'Não foi possível conectar ao servidor.',
      );
    }

    if (response.statusCode == 401) {
      final refreshed = await AuthService().refresh();
      if (refreshed) {
        response =
            await request(_headers).timeout(const Duration(seconds: 10));
      }
    }

    final body = response.body.isEmpty
        ? null
        : jsonDecode(response.body) as dynamic;
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    final message = body is Map ? body['message'] : null;
    throw AttendanceException(
      message is List
          ? message.join('\n')
          : (message?.toString() ??
              'Erro ${response.statusCode} no servidor.'),
    );
  }

  Future<List<AulaIdentitas>> listForTeacher(String teacherId) async {
    final body = await _send(
      (headers) => _client.get(
        _uri('/classes/teacher/$teacherId'),
        headers: headers,
      ),
    ) as List<dynamic>;
    return [
      for (final item in body)
        AulaIdentitas.fromJson(item as Map<String, dynamic>)
    ];
  }

  Future<List<AulaIdentitas>> listForStudent(String studentId) async {
    final body = await _send(
      (headers) => _client.get(
        _uri('/classes/student/$studentId'),
        headers: headers,
      ),
    ) as List<dynamic>;
    return [
      for (final item in body)
        AulaIdentitas.fromJson(item as Map<String, dynamic>)
    ];
  }

  Future<List<StudentIdentitas>> listStudents() async {
    final body = await _send(
      (headers) => _client.get(
        _uri('/users'),
        headers: headers,
      ),
    ) as List<dynamic>;
    return [
      for (final item in body)
        StudentIdentitas.fromJson(item as Map<String, dynamic>)
    ];
  }

  Future<AulaIdentitas> openAttendance(
    String classId, {
    DateTime? date,
  }) async {
    final query = date == null
        ? ''
        : '?date=${Uri.encodeComponent(date.toIso8601String())}';
    final body = await _send(
      (headers) => _client.patch(
        _uri('/classes/$classId/attendance/open$query'),
        headers: headers,
      ),
    );
    return AulaIdentitas.fromJson(body as Map<String, dynamic>);
  }

  Future<AulaIdentitas> closeAttendance(String classId) async {
    final body = await _send(
      (headers) => _client.patch(
        _uri('/classes/$classId'),
        headers: headers,
        body: jsonEncode({'attendanceStatus': 'closed'}),
      ),
    );
    return AulaIdentitas.fromJson(body as Map<String, dynamic>);
  }

  Future<AulaIdentitas> markAttendance(
    String classId,
    List<String> presentStudentIds, {
    DateTime? date,
  }) async {
    final body = await _send(
      (headers) => _client.post(
        _uri('/classes/$classId/students/attendance'),
        headers: headers,
        body: jsonEncode({
          'presentStudentIds': presentStudentIds,
          if (date != null) 'date': date.toIso8601String(),
        }),
      ),
    );
    return AulaIdentitas.fromJson(body as Map<String, dynamic>);
  }

  Future<AulaIdentitas> markAttendanceByNfc(
    String classId,
    List<String> nfcUids, {
    DateTime? date,
  }) async {
    final body = await _send(
      (headers) => _client.post(
        _uri('/classes/$classId/students/attendance/nfc'),
        headers: headers,
        body: jsonEncode({
          'nfcUids': nfcUids,
          if (date != null) 'date': date.toIso8601String(),
        }),
      ),
    );
    return AulaIdentitas.fromJson(body as Map<String, dynamic>);
  }
}
