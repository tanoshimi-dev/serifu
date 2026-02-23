import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;

  const KeyboardShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyH): () => context.go('/'),
        const SingleActivator(LogicalKeyboardKey.keyF): () =>
            context.go('/feed'),
        const SingleActivator(LogicalKeyboardKey.keyW): () =>
            context.go('/write'),
        const SingleActivator(LogicalKeyboardKey.keyN): () =>
            context.go('/notifications'),
        const SingleActivator(LogicalKeyboardKey.keyP): () =>
            context.go('/profile'),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
