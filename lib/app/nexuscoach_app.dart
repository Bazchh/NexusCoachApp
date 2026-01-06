import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import '../features/onboarding/language_gate.dart';

class NexusCoachApp extends StatelessWidget {
  const NexusCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexusCoach',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: textTheme,
      ),
      home: const LanguageGate(),
    );
  }
}
