import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
              middle: Text(title!),
              automaticallyImplyLeading: showBackButton,
              trailing: actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
      child: SafeArea(child: body),
    );
  }
}
