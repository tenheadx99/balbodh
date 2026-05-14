import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class BalBodhApp extends StatelessWidget {
  const BalBodhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'बालबोध - BalBodh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: HomeScreen(),
    );
  }
}
