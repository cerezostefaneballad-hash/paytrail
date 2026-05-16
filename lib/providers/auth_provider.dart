import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  String? token;
  Map<String, dynamic>? user;

  ApiService get api => _api;
  bool get isLoggedIn => token != null;

  Future<void> login(String username, String password) async {
    final res = await _api.login(username, password);
    token = res['token'];
    user = res['user'];
    _api.setToken(token);
    await _storage.write(key: 'token', value: token!);
    notifyListeners();
  }

  Future<void> logout() async {
    try { await _api.logout(); } catch (_) {}
    token = null;
    user = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> tryRestore() async {
    token = await _storage.read(key: 'token');
    if (token != null) _api.setToken(token);
    notifyListeners();
  }
}