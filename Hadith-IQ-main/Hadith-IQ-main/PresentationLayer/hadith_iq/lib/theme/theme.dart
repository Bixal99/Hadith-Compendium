import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF710E1A),
  onPrimary: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFD6C091),
  secondaryFixedDim: const Color(0xFFDCC9A1),
  onSecondary: const Color(0xFFFFFFFF),
  tertiary: const Color(0xFF1B4B29),
  onTertiary: const Color(0xFFFFFFFF),
  error: const Color.fromARGB(255, 201, 52, 45),
  onError: const Color(0xFFFFFFFF),
  surface: const Color(0xFFFFFCF1),
  onSurface: const Color(0xFF131919),
  // surfaceContainerLowest: Colors.grey[50]!, // Lowest background color
  // surfaceContainerLow: Colors.grey[100]!, // Slightly elevated
  surfaceContainer: const Color(0xFFFFFFFF), // Default surface
  surfaceContainerHigh: Colors.grey[200], // Elevated surface
  surfaceContainerHighest: Colors.grey, // Highest elevation
  inverseSurface: const Color(0xFF131919), // Used in dark mode elevated content
  // onInverseSurface: const Color(0xFFF9F9F9),
);

ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFF1B4B29),
  onPrimary: const Color(0xFFFFFFFF), // Darker text color on primary
  secondary: const Color(0xFFD6C091), // Same secondary color
  onSecondary: const Color(0xFF131919), // White text/icons on secondary
  error: const Color(0xFFCF6679), // Material dark theme error color
  onError: const Color(0xFF131919), // Text color on error (dark background)
  surface: const Color(0xFF131919), // Dark surface color
  onSurface: const Color(0xFFD6C091), // Light text/icons on dark surfaces
  // surfaceContainerLowest: Color(0xFF131919), // Darkest background
  // surfaceContainerLow: Color(0xFF131919), // Slightly lighter
  // surfaceContainer: Color(0xFF131919), // Default surface
  surfaceContainerHigh: Colors.grey[200], // Elevated surface
  surfaceContainerHighest: Colors.grey, // Highest elevated surface
  inverseSurface: const Color(0xFF131919), // Light inverse surface
  onInverseSurface: const Color(0xFF1E1E1E), // Text color on light inverse surface
);

ThemeData lightMode = ThemeData(
  colorScheme: lightColorScheme,
  useMaterial3: true,
  textTheme: GoogleFonts.robotoTextTheme(),
);
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  textTheme: GoogleFonts.robotoTextTheme(),
);
