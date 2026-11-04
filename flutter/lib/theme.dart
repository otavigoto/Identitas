import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Cores do Figma "Identitas Designs" (Props > cores)
class AppColors {
  static const amarelo = Color(0xFFF9FF2E);
  static const creme = Color(0xFFFEFFD9);
  static const fundo = Color(0xFF1E1E1E);
  static const preto = Colors.black;
  static const branco = Colors.white;
}

// Títulos usam SF Pro no Figma (fonte padrão do iOS); textos menores usam Urbanist.
TextStyle urbanist({double size = 12, FontWeight weight = FontWeight.w500, Color color = AppColors.preto}) =>
    GoogleFonts.urbanist(fontSize: size, fontWeight: weight, color: color);

final appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.fundo,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.amarelo, brightness: Brightness.dark),
);
