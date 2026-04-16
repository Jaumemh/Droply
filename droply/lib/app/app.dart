import 'package:droply/features/shell/presentation/infrastructure_home_page.dart';
import 'package:flutter/material.dart';

class DroplyApp extends StatelessWidget {
  const DroplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0066CC),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Droply',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFDCE4F0)),
          ),
        ),
      ),
      home: const InfrastructureHomePage(),
    );
  }
}
