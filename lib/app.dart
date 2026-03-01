import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget for the Lovepin application.
///
/// Uses [MaterialApp.router] with [GoRouter] for declarative navigation and
/// applies the pastel-themed [AppTheme].
class LovepinApp extends ConsumerWidget {
  const LovepinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lovepin',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,

      // Router
      routerConfig: router,
    );
  }
}
