import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'adaptive_widget.dart';

/// Estrutura de tela: Scaffold + AppBar (Material) ou
/// CupertinoPageScaffold + CupertinoNavigationBar (iOS).
class AdaptiveScaffold extends AdaptiveWidget {
  final String? title;
  final Widget body;
  final List<Widget> actions;
  final bool showBackButton;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions = const [],
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget buildMaterial(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
            ),
      body: SafeArea(child: body),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: title == null
          ? null
          : CupertinoNavigationBar(
              // Sem isso o iOS deixa a barra transparente até o conteúdo rolar,
              // e o título branco some sobre o fundo claro.
              automaticBackgroundVisibility: false,
              backgroundColor: AppColors.primary,
              border: null,
              middle: Text(title!),
              // O botão de voltar padrão usa a cor primária, que some na barra
              // primária; por isso ele é montado aqui em branco.
              automaticallyImplyLeading: false,
              leading: showBackButton && Navigator.of(context).canPop()
                  ? const CupertinoNavigationBarBackButton(color: CupertinoColors.white)
                  : null,
              trailing: actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
      child: SafeArea(child: body),
    );
  }
}
