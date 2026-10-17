import 'package:flutter/foundation.dart';

/// Base dos controllers (o "C" do MVC).
///
/// Guarda o estado comum de carregamento e erro e avisa a view
/// quando algo muda (`notifyListeners`). A view escuta com `ListenableBuilder`.
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @protected
  void setLoading(bool value) {
    _isLoading = value;
    notify();
  }

  @protected
  void setError(String? message) {
    _errorMessage = message;
    notify();
  }

  void clearError() => setError(null);

  /// Executa uma ação assíncrona controlando loading e erro.
  /// Retorna `true` se terminou sem exceção.
  @protected
  Future<bool> runAsync(Future<void> Function() action) async {
    _errorMessage = null;
    setLoading(true);
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      setLoading(false);
    }
  }

  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
