import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AluConnectApp extends ConsumerWidget {
  const AluConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ALU Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Paints the peach gradient once behind every screen. Individual
      // Scaffolds stay transparent (see scaffoldBackgroundColor in
      // AppTheme) so this shows through everywhere without editing
      // each screen file individually.
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: child,
        );
      },
    );
  }
}
