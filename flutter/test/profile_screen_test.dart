import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identitas/api_client.dart';
import 'package:identitas/auth_api.dart';
import 'package:identitas/screens/profile_screen.dart';
import 'package:identitas/services/nfc_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('exibe perfil digital com dados reais e sem telas extras', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final auth = AuthApi(
      ApiClient(
        baseUrl: 'http://api.teste',
        session: Session()..accessToken = 'access-token',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/auth/profile');
          expect(request.headers['Authorization'], 'Bearer access-token');
          return http.Response(
            jsonEncode({
              '_id': 'student-id',
              'name': 'Pilar Brandão',
              'ra': '24012345',
              'role': 'STUDENT',
              'course': 'Sistemas de Informação',
              'periodSemester': '6',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(auth: auth)));
    await tester.pumpAndSettle();

    expect(find.text('Meu Perfil'), findsOneWidget);
    expect(find.text('Pilar Brandão'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(find.text('24012345'), findsOneWidget);
    expect(find.text('Sistemas de Informação'), findsOneWidget);
    expect(find.text('6º semestre'), findsOneWidget);
    expect(find.byKey(const Key('perfil-sair')), findsOneWidget);
    expect(find.text('Abrir histórico'), findsNothing);
    expect(find.text('Abrir carteirinha digital'), findsNothing);
  });

  testWidgets('vincula o NFC ao próprio usuário a partir do perfil', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final requisicoes = <http.Request>[];
    final auth = AuthApi(
      ApiClient(
        baseUrl: 'http://api.teste',
        session: Session()..accessToken = 'access-token',
        httpClient: MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path == '/auth/profile') {
            return http.Response(
              jsonEncode({
                '_id': 'student-id',
                'name': 'Pilar Brandão',
                'ra': '24012345',
                'role': 'STUDENT',
                'course': 'Sistemas de Informação',
                'periodSemester': '6',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.method, 'PATCH');
          expect(request.url.path, '/users/student-id/nfc');
          expect(request.headers['Authorization'], 'Bearer access-token');
          expect(jsonDecode(request.body), {'nfcUid': 'A1B2C3'});
          return http.Response(
            jsonEncode({
              '_id': 'student-id',
              'name': 'Pilar Brandão',
              'ra': '24012345',
              'role': 'STUDENT',
              'nfcUid': 'A1B2C3',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(auth: auth, nfcService: _NfcUidFake()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('perfil-vincular-nfc')));
    await tester.pumpAndSettle();

    expect(find.text('NFC UID: A1B2C3'), findsOneWidget);
    expect(find.text('Cartão NFC vinculado.'), findsOneWidget);
    expect(requisicoes.map((request) => request.url.path), [
      '/auth/profile',
      '/users/student-id/nfc',
    ]);
  });
}

class _NfcUidFake extends NfcService {
  @override
  Future<String> lerUid() async => 'A1B2C3';
}
