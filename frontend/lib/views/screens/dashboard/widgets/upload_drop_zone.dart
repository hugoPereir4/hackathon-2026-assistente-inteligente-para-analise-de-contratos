import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/platform/app_platform.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../models/arquivo_selecionado.dart';
import '../../../components/components.dart';

/// Zona de upload com borda tracejada.
///
/// Na web aceita arrastar e soltar; no celular só mostra o botão de seleção.
class UploadDropZone extends StatelessWidget {
  final bool arrastando;
  final String? arquivoEmEnvio;
  final VoidCallback onSelecionar;
  final ValueChanged<bool> onArrastandoChanged;
  final ValueChanged<List<XFile>> onArquivosSoltos;

  const UploadDropZone({
    super.key,
    required this.arrastando,
    required this.arquivoEmEnvio,
    required this.onSelecionar,
    required this.onArrastandoChanged,
    required this.onArquivosSoltos,
  });

  bool get _aceitaArrastar => AppPlatform.instance.isWeb;
  bool get _enviando => arquivoEmEnvio != null;

  @override
  Widget build(BuildContext context) {
    final zona = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: arrastando ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DashedBorder(
        color: arrastando ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
        strokeWidth: arrastando ? 2 : 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
          child: _enviando ? _conteudoEnviando() : _conteudoInicial(),
        ),
      ),
    );

    if (!_aceitaArrastar) return zona;
    return DropTarget(
      enable: !_enviando,
      onDragEntered: (_) => onArrastandoChanged(true),
      onDragExited: (_) => onArrastandoChanged(false),
      onDragDone: (details) => onArquivosSoltos(details.files),
      child: zona,
    );
  }

  Widget _conteudoInicial() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.pdf, color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: 20),
        AppText.subtitle(
          _aceitaArrastar ? 'Arraste e solte o seu arquivo aqui' : 'Envie seu documento',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const AppText.caption(
          'Suporta PDF (máx. ${ArquivoSelecionado.tamanhoMaximoMb} MB)',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AdaptiveButton.secondary(
          label: _aceitaArrastar ? 'Ou selecione do computador' : 'Selecionar arquivo',
          expanded: false,
          onPressed: onSelecionar,
        ),
      ],
    );
  }

  Widget _conteudoEnviando() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const AdaptiveLoading(),
        const SizedBox(height: 20),
        const AppText.subtitle('Enviando documento...', textAlign: TextAlign.center),
        const SizedBox(height: 6),
        AppText.caption(arquivoEmEnvio!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
      ],
    );
  }
}
