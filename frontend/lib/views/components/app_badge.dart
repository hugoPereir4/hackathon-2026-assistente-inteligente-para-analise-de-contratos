import 'package:flutter/widgets.dart';

/// Etiqueta pequena em pílula (ex.: "92% Match", "Analisando").
/// Fundo é a [color] bem clara e o texto é a [color] escurecida, para contraste.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? leading;

  const AppBadge({super.key, required this.label, required this.color, this.leading});

  Color get _textColor {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textColor),
          ),
        ],
      ),
    );
  }
}
