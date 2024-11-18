import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'screens/home_page.dart';
import 'widgets/custom_navigation_bar.dart';

// Aktuell wird hier Flutter nur angewiesen, die in MyApp() definierte App auszuführen.
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanDocus', //Name wird der App gegeben
      theme: ThemeData(
          //Visuelles Design wird erstellt
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 126, 11, 137))),
      home: HomePage(), //Home Widget wird erstellt
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
