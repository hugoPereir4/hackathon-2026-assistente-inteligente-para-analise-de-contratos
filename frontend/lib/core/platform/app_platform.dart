import 'package:flutter/foundation.dart';

/// Tipo de interface que o app vai renderizar.
enum UiStyle { material, cupertino }

/// Verifica em qual ambiente o app foi buildado e decide qual
/// biblioteca de componentes usar:
/// - Web     -> Material
/// - Android -> Material
/// - iOS     -> Cupertino
///
/// Para testar o visual Cupertino no navegador, rode com:
///   flutter run -d chrome --dart-define=UI_STYLE=cupertino
class AppPlatform {
  AppPlatform._();

  static final AppPlatform instance = AppPlatform._();

  static const String _forcedStyle = String.fromEnvironment('UI_STYLE');

  /// `kIsWeb` é verificado primeiro: no Safari do iPhone o
  /// `defaultTargetPlatform` também é iOS, mas na web queremos Material.
  bool get isWeb => kIsWeb;

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  UiStyle get uiStyle {
    if (_forcedStyle == 'cupertino') return UiStyle.cupertino;
    if (_forcedStyle == 'material') return UiStyle.material;
    return isIOS ? UiStyle.cupertino : UiStyle.material;
  }

  bool get useCupertino => uiStyle == UiStyle.cupertino;

  bool get useMaterial => uiStyle == UiStyle.material;
}
