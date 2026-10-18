import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_tokens.dart';

/// Onde os tokens JWT ficam guardados entre aberturas do app.
abstract class TokenStorage {
  Future<AuthTokens?> ler();
  Future<void> salvar(AuthTokens tokens);
  Future<void> limpar();
}

/// Usa SharedPreferences (localStorage na web). Suficiente para o hackathon;
/// em produção, no mobile, o ideal seria flutter_secure_storage.
class SharedPrefsTokenStorage implements TokenStorage {
  static const _chaveAccess = 'auth.access';
  static const _chaveRefresh = 'auth.refresh';

  @override
  Future<AuthTokens?> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_chaveAccess);
    final refresh = prefs.getString(_chaveRefresh);
    if (access == null || refresh == null) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> salvar(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveAccess, tokens.access);
    await prefs.setString(_chaveRefresh, tokens.refresh);
  }

  @override
  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveAccess);
    await prefs.remove(_chaveRefresh);
  }
}
