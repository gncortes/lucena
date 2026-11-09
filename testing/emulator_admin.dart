import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:lucena/config/ambiente.dart';
import 'package:lucena/data/services/firebase/firebase_bootstrap.dart';

/// Uma conta do Auth Emulator: o uid e o token para chamar as Functions.
typedef EmulatorAccount = ({String uid, String idToken});

/// O lado do admin nos cenários do Patrol no Emulator Suite (roteiro de
/// `docs/tasks/E1.19-qa-r5.md`): cria e verifica contas pelo Auth, chama as
/// Functions do painel como administrador e lê o Firestore como dono (o
/// token `owner` do emulador passa por cima das regras).
///
/// Só fala com [FirebaseEmulador.host] (o computador visto do emulador
/// Android): nada sai para o projeto de verdade.
class EmulatorAdmin {
  EmulatorAdmin({http.Client? client}) : _http = client ?? http.Client();

  /// A senha das contas `alunoNN@teste.lucena` de
  /// `tools/emulador_contas_qa.py` (só existe no emulador).
  static const studentPassword = 'aluno-teste-123';
  static const adminEmail = 'admin-qa@teste.lucena';
  static const adminPassword = 'admin-teste-123';

  /// A região das Functions (`functions/src/comum/config.ts`).
  static const region = 'southamerica-east1';

  static String student(int number) =>
      'aluno${number.toString().padLeft(2, '0')}@teste.lucena';

  final http.Client _http;
  EmulatorAccount? _admin;

  /// O projeto do Firebase do flavor. O cenário pode chamar o admin antes de o
  /// app abrir (e iniciar o Firebase): por isso cada chamada que usa o
  /// projeto passa antes por [_firebase].
  String get project => Firebase.app().options.projectId;

  Future<void> _firebase() async {
    if (Firebase.apps.isEmpty) await initializeFirebaseApp(emulador: true);
  }

  static final _key = emulatorFirebaseOptions.apiKey;
  String get _auth =>
      'http://${FirebaseEmulador.host}:${FirebaseEmulador.authPort}';
  String get _accounts => '$_auth/identitytoolkit.googleapis.com/v1/accounts';
  String get _documents =>
      'http://${FirebaseEmulador.host}:${FirebaseEmulador.firestorePort}'
      '/v1/projects/$project/databases/(default)/documents';
  static const _owner = {
    'Authorization': 'Bearer owner',
    'Content-Type': 'application/json',
  };

  // --- Auth -----------------------------------------------------------------

  /// Entra com [email]; com [create], cria a conta se ela não existe.
  Future<EmulatorAccount> signIn(
    String email,
    String password, {
    bool create = false,
  }) async {
    final login = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };
    var answer = await _post('$_accounts:signInWithPassword?key=$_key', login);
    if (create && answer['idToken'] == null) {
      answer = await _post('$_accounts:signUp?key=$_key', login);
    }
    final idToken = answer['idToken'];
    if (idToken is! String) {
      throw StateError('$email não entrou no emulador: ${answer['error']}');
    }
    return (uid: answer['localId'] as String, idToken: idToken);
  }

  /// Se o e-mail da conta já está verificado.
  Future<bool> emailVerified(EmulatorAccount account) async {
    final answer = await _post('$_accounts:lookup?key=$_key', {
      'idToken': account.idToken,
    });
    final users = answer['users'];
    return users is List &&
        users.isNotEmpty &&
        (users.first as Map)['emailVerified'] == true;
  }

  /// Verifica o e-mail pelo caminho do link: pede o código, lê na lista do
  /// emulador e o aplica (como `tools/emulador_contas_qa.py`).
  Future<void> verifyEmail(EmulatorAccount account, String email) async {
    await _firebase();
    await _post('$_accounts:sendOobCode?key=$_key', {
      'requestType': 'VERIFY_EMAIL',
      'idToken': account.idToken,
    });
    final list = await _get('$_auth/emulator/v1/projects/$project/oobCodes');
    final codes = (list['oobCodes'] as List? ?? const [])
        .cast<Map<String, Object?>>()
        .where(
          (c) => c['email'] == email && c['requestType'] == 'VERIFY_EMAIL',
        );
    if (codes.isEmpty) throw StateError('Sem código de verificação: $email');
    await _post('$_accounts:update?key=$_key', {
      'oobCode': codes.last['oobCode'],
    });
  }

  /// Troca a senha da conta [uid] como dono do emulador (a conta da semente
  /// entra no teste com uma senha de teste conhecida, sem ler a do script).
  Future<void> setPassword(String uid, String password) async {
    await _firebase();
    final response = await _http.post(
      Uri.parse(
        '$_auth/identitytoolkit.googleapis.com/v1/projects/$project'
        '/accounts:update',
      ),
      headers: _owner,
      body: jsonEncode({'localId': uid, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw StateError('senha de $uid não mudou: ${response.body}');
    }
  }

  // --- Functions --------------------------------------------------------------

  /// A conta de administrador (criada na primeira vez, com `admins/{uid}`).
  Future<EmulatorAccount> admin() async {
    final known = _admin;
    if (known != null) return known;
    final account = await signIn(adminEmail, adminPassword, create: true);
    await write('admins/${account.uid}', {'email': adminEmail, 'qa': true});
    return _admin = account;
  }

  /// Chama a Function [name] do painel como administrador e devolve o
  /// `result`.
  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> data,
  ) async {
    await _firebase();
    final account = await admin();
    final response = await _http.post(
      Uri.parse(
        'http://${FirebaseEmulador.host}:${FirebaseEmulador.functionsPort}'
        '/$project/$region/$name',
      ),
      headers: {
        'Authorization': 'Bearer ${account.idToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'data': data}),
    );
    final answer = jsonDecode(response.body) as Map<String, Object?>;
    if (answer['error'] != null) {
      throw StateError('$name falhou: ${answer['error']}');
    }
    final result = answer['result'];
    return result is Map ? result.cast<String, Object?>() : const {};
  }

  Future<Map<String, Object?>> giveCourse(
    String uid, {
    String course = 'pilares',
    String origin = 'presente',
    bool sendPush = false,
  }) => call('darCurso', {
    'uid': uid,
    'curso': course,
    'origem': origin,
    'plano': 'vitalicio',
    'motivo': 'Roteiro de QA R5',
    'enviarPush': sendPush,
  });

  Future<Map<String, Object?>> revokeCourse(
    String uid, {
    String course = 'pilares',
  }) => call('revogarCurso', {
    'uid': uid,
    'curso': course,
    'motivo': 'Roteiro de QA R5',
  });

  Future<Map<String, Object?>> undo(String uid, String recordId) =>
      call('desfazer', {'uid': uid, 'registroId': recordId});

  Future<Map<String, Object?>> block(String uid) =>
      call('bloquearConta', {'uid': uid, 'motivo': 'Roteiro de QA R5'});

  Future<Map<String, Object?>> unblock(String uid) =>
      call('desbloquearConta', {'uid': uid, 'motivo': 'Roteiro de QA R5'});

  // --- Firestore (como dono) ----------------------------------------------------

  /// O documento [path] em valores simples; nulo se não existe.
  Future<Map<String, Object?>?> read(String path) async {
    await _firebase();
    final response = await _http.get(
      Uri.parse('$_documents/$path'),
      headers: _owner,
    );
    if (response.statusCode == 404) return null;
    final doc = jsonDecode(response.body) as Map<String, Object?>;
    return _fields(doc['fields']);
  }

  /// Grava (substitui) o documento [path] com [data] em texto e booleanos.
  Future<void> write(String path, Map<String, Object?> data) async {
    await _firebase();
    final response = await _http.patch(
      Uri.parse('$_documents/$path'),
      headers: _owner,
      body: jsonEncode({
        'fields': {for (final e in data.entries) e.key: _encode(e.value)},
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Firestore recusou $path: ${response.body}');
    }
  }

  /// Apaga o documento [path] (as subcoleções ficam).
  Future<void> delete(String path) async {
    await _firebase();
    final response = await _http.delete(
      Uri.parse('$_documents/$path'),
      headers: _owner,
    );
    if (response.statusCode != 200) {
      throw StateError('Firestore não apagou $path: ${response.body}');
    }
  }

  /// Muda só os campos de [data] em [path]; campo com valor nulo sai do
  /// documento (o resto fica como está).
  Future<void> merge(String path, Map<String, Object?> data) async {
    await _firebase();
    final mask = [for (final k in data.keys) 'updateMask.fieldPaths=$k'];
    final response = await _http.patch(
      Uri.parse('$_documents/$path?${mask.join('&')}'),
      headers: _owner,
      body: jsonEncode({
        'fields': {
          for (final e in data.entries)
            if (e.value != null) e.key: _encode(e.value),
        },
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Firestore recusou $path: ${response.body}');
    }
  }

  /// Os documentos de [collection] com [field] igual a [value].
  Future<List<Map<String, Object?>>> where(
    String collection,
    String field,
    String value,
  ) async {
    await _firebase();
    final response = await _http.post(
      Uri.parse('$_documents:runQuery'),
      headers: _owner,
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': collection},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': field},
              'op': 'EQUAL',
              'value': {'stringValue': value},
            },
          },
        },
      }),
    );
    return [
      for (final row in jsonDecode(response.body) as List)
        if ((row as Map)['document'] case final Map doc)
          _fields(doc['fields']) ?? const {},
    ];
  }

  /// Espera até [check] valer para o documento [path] (o app grava sem
  /// avisar o teste).
  Future<Map<String, Object?>?> waitFor(
    String path,
    bool Function(Map<String, Object?>? doc) check, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final watch = Stopwatch()..start();
    while (true) {
      final doc = await read(path);
      if (check(doc)) return doc;
      if (watch.elapsed > timeout) {
        throw StateError('$path não chegou ao esperado: $doc');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  void close() => _http.close();

  Future<Map<String, Object?>> _post(String url, Map<String, Object?> body) =>
      _http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .then((r) => jsonDecode(r.body) as Map<String, Object?>);

  Future<Map<String, Object?>> _get(String url) => _http
      .get(Uri.parse(url))
      .then((r) => jsonDecode(r.body) as Map<String, Object?>);

  static Map<String, Object?>? _fields(Object? fields) => fields is Map
      ? {for (final e in fields.entries) '${e.key}': _decode(e.value)}
      : null;

  static Object? _decode(Object? value) {
    if (value is! Map) return null;
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.tryParse('${value['integerValue']}');
    }
    if (value.containsKey('doubleValue')) return value['doubleValue'];
    if (value.containsKey('timestampValue')) {
      return DateTime.tryParse('${value['timestampValue']}');
    }
    if (value.containsKey('mapValue')) {
      return _fields((value['mapValue'] as Map)['fields']) ?? const {};
    }
    if (value.containsKey('arrayValue')) {
      final list = (value['arrayValue'] as Map)['values'] as List? ?? const [];
      return [for (final item in list) _decode(item)];
    }
    return null;
  }

  static Map<String, Object?> _encode(Object? value) => switch (value) {
    final bool b => {'booleanValue': b},
    final int i => {'integerValue': '$i'},
    final String s => {'stringValue': s},
    final DateTime d => {'timestampValue': d.toUtc().toIso8601String()},
    final Map<String, Object?> m => {
      'mapValue': {
        'fields': {for (final e in m.entries) e.key: _encode(e.value)},
      },
    },
    _ => {'nullValue': null},
  };
}
