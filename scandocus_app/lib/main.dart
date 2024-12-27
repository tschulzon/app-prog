import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'utils/document_provider.dart';

// This file is the entry point of the application.
// It starts with the runApp() Method
Future<void> main() async {
  runApp(
    // This provider notifies every widget which has subscriced the provider, when a state has changed
    ChangeNotifierProvider(
      create: (context) => DocumentProvider(),
      child: MyApp(), // Entry point from the app
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
    Color baseColor = Color(0xFF202124);

    return MaterialApp(
      title: 'Scan2Doc', // Name of the application
      theme: ThemeData(
        // Creating a visual standard theme
        useMaterial3: true,

        // Creating a theme for the timepicker in the filter dialog
        timePickerTheme: TimePickerThemeData(
          backgroundColor: baseColor,
          hourMinuteTextColor: Color.fromARGB(174, 11, 185, 216),
          dialHandColor: baseColor,
          hourMinuteColor: baseColor,
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                BorderSide(color: Color.fromARGB(174, 11, 185, 216), width: 2),
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
            foregroundColor: Color.fromARGB(174, 11, 185, 216),
            textStyle: TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 60, 221, 121),
            textStyle: TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Creating a theme for the navigationbar
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

      // Startpage is the Homepage, where all documents, which exist in solr, will be shown
      home: HomePage(),
    );
  }
}
