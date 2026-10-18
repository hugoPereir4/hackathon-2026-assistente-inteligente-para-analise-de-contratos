/// Configuração definida na hora do build/run via `--dart-define`.
///
/// Padrão: mocks (o app roda sem backend). Para usar a API Django:
///   flutter run -d chrome --dart-define=USE_API=true --dart-define=API_URL=http://localhost:8000
///
/// No emulador Android, `localhost` é o próprio emulador; use
///   --dart-define=API_URL=http://10.0.2.2:8000
abstract final class AppConfig {
  static const bool useApi = bool.fromEnvironment('USE_API');

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Prefixo das rotas do Django (config/urls.py).
  static const String apiPrefix = '/api/v1/';

  static const Duration requestTimeout = Duration(seconds: 30);

  /// POST /documents/{id}/analyze/ é síncrono e o Gemini tem timeout de 60 s.
  static const Duration analysisTimeout = Duration(seconds: 120);
}
