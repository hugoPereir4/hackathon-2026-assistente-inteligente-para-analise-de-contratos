/// Par de tokens do SimpleJWT. O `access` expira rápido (5 min por padrão)
/// e é renovado com o `refresh` em POST /auth/refresh/.
class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(access: json['access'] as String, refresh: json['refresh'] as String);
  }

  AuthTokens copyWith({String? access, String? refresh}) =>
      AuthTokens(access: access ?? this.access, refresh: refresh ?? this.refresh);
}
