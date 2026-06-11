import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'widgets/time_limit_guard.dart';

class BalBodhApp extends StatelessWidget {
  const BalBodhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'बालबोध - BalBodh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) =>
          TimeLimitGuard(child: child ?? const SizedBox.shrink()),
      home: HomeScreen(),
    );
  }
}
