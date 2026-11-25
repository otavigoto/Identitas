import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IdentitasColors {
  static const amarelo = Color(0xFFF9FF2E);
  static const creme = Color(0xFFFEFFD9);
  static const fundo = Color(0xFF1E1E1E);
  static const preto = Colors.black;
  static const branco = Colors.white;
}

TextStyle identitasText({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = IdentitasColors.preto,
}) {
  return GoogleFonts.urbanist(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

/// Tema global do app.
final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF9FF2E)),
  scaffoldBackgroundColor: Colors.white,
);
