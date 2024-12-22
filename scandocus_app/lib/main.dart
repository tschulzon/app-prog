import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import 'package:scandocus_app/widgets/documents_view.dart';
import 'screens/home_page.dart';
import 'utils/document_provider.dart';

Future<void> main() async {
  // Start der App
  runApp(
    ChangeNotifierProvider(
      create: (context) => DocumentProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    Color baseColor = Color(0xFF202124);
    return MaterialApp(
      title: 'ScanDocus', //Name wird der App gegeben
      theme: ThemeData(
        //Visuelles Design wird erstellt
        useMaterial3: true,
        timePickerTheme: TimePickerThemeData(
          backgroundColor: baseColor, // Dunkler Hintergrund
          hourMinuteTextColor: Color.fromARGB(
              174, 11, 185, 216), // Weißer Text für Stunden und Minuten
          dialHandColor: baseColor, // Blauer Zeiger
          hourMinuteColor: baseColor, // Weiße Farbe für die Stunden und Minuten
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Abgerundete Ecken
            side: BorderSide(
                color: Color.fromARGB(174, 11, 185, 216),
                width: 2), // Rahmenfarbe und -breite
          ),
          dialBackgroundColor: Color.fromARGB(174, 11, 185, 216),
          entryModeIconColor: Color.fromARGB(174, 11, 185, 216),
          helpTextStyle: GoogleFonts.quicksand(
            textStyle: TextStyle(
              color: Color.fromARGB(219, 11, 185, 216),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: Color.fromARGB(
                174, 11, 185, 216), // Textfarbe für den "Cancel"-Button
            textStyle: TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 14, // Schriftgröße für "Cancel"
              fontWeight: FontWeight.bold,
            ),
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: Color.fromARGB(
                255, 60, 221, 121), // Textfarbe für den "Cancel"-Button
            textStyle: TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 14, // Schriftgröße für "Cancel"
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: baseColor,
            indicatorColor: Color.fromARGB(219, 11, 185, 216),
            labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(219, 11, 185, 216),
            ))),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(219, 11, 185, 216),
        ),
        scaffoldBackgroundColor: baseColor,
        appBarTheme: AppBarTheme(
          backgroundColor: baseColor,
        ),
      ),
      home: HomePage(),
    );
  }
}

class CommutePage extends StatelessWidget {
  const CommutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Commute Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
