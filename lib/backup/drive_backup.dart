import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'backup_data.dart';

class DriveSnapshot {
  final String id;
  final String name;
  DriveSnapshot(this.id, this.name);
}

class DriveBackup {
  static const clientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  static Future<void>? _initialization;
  GoogleSignInAccount? _account;
  String? get email => _account?.email;
  bool get configured => clientId.isNotEmpty;

  Future<void> connect() async {
    if (!configured)
      throw StateError(
        'Google backup is not configured in this build. Use Export backup for now.',
      );
    await (_initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: clientId,
    ));
    final account = await GoogleSignIn.instance.authenticate(scopeHint: scopes);
    await account.authorizationClient.authorizeScopes(scopes);
    _account = account;
  }

  Future<void> disconnect() async {
    if (_initialization != null) await GoogleSignIn.instance.signOut();
    _account = null;
  }

  Future<Map<String, String>> _headers() async {
    final account = _account;
    if (account == null) throw StateError('Connect your Google account first.');
    final auth = await account.authorizationClient.authorizationForScopes(
      scopes,
    );
    if (auth == null)
      throw StateError('Google access expired. Reconnect your account.');
    return {'Authorization': 'Bearer ${auth.accessToken}'};
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Google Drive request failed (${response.statusCode}). Check connection and reconnect if needed.',
      );
    }
  }

  Future<void> upload(BackupData data) async {
    final headers = await _headers();
    final boundary = 'shan_${DateTime.now().microsecondsSinceEpoch}';
    final metadata = jsonEncode({
      'name': 'ShanReminder-${data.createdAt.toUtc().toIso8601String()}.json',
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    });
    final body =
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metadata\r\n'
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${data.encode()}\r\n--$boundary--\r\n';
    final response = await http
        .post(
          Uri.https('www.googleapis.com', '/upload/drive/v3/files', {
            'uploadType': 'multipart',
          }),
          headers: {
            ...headers,
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: utf8.encode(body),
        )
        .timeout(const Duration(seconds: 45));
    _check(response);
  }

  Future<List<DriveSnapshot>> list() async {
    final response = await http
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/files', {
            'spaces': 'appDataFolder',
            'q': "trashed = false and name contains 'ShanReminder-'",
            'orderBy': 'createdTime desc',
            'pageSize': '100',
            'fields': 'files(id,name)',
          }),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    _check(response);
    return ((jsonDecode(response.body) as Map)['files'] as List)
        .map((f) => DriveSnapshot(f['id'] as String, f['name'] as String))
        .toList();
  }

  Future<BackupData> download(DriveSnapshot snapshot) async {
    final response = await http
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/files/${snapshot.id}', {
            'alt': 'media',
          }),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    _check(response);
    return BackupData.decode(utf8.decode(response.bodyBytes));
  }
}
