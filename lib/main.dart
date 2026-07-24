import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_download_screen.dart';

void main() {
  runApp(const CaptionGeneratorApp());
} 

class CaptionGeneratorApp extends StatelessWidget {
  const CaptionGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper Captions',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurpleAccent,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.purpleAccent,
          surface: Colors.grey.shade900,
        ),
      ),
      home: const SplashDownloadScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
