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

import '../widgets/documents_view.dart';
import '../widgets/custom_navigation_bar.dart';
import '../screens/ocr_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;
  String searchQuery = "";

  var showText = "Hier wird Text angezeigt";

  File? selectedImage; // Ausgewähltes Bild als Datei
  final ImagePicker picker = ImagePicker();

  // Methode zum Auswählen eines Bildes
  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery); // Bild aus Galerie auswählen
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          _currentPageIndex = 2;

          navigateToOCRScreen();
        });
      }
    } catch (e) {
      setState(() {
        showText = "Fehler beim Bildauswählen: $e";
      });
    }
  }

  final List<Widget> _pages = [
    const DocumentsView(),
    //OcrPage(),
    Center(child: Text("Kamera Page")),
    Center(child: Text("Galerie Page")),
  ];

  // Navigiere zum OCR-Prozess-Bildschirm und übergebe das Bild
  void navigateToOCRScreen() {
    if (selectedImage != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OcrProcessView(selectedImage: selectedImage),
        ),
      );
    } else {
      // Optional: Nachricht anzeigen, wenn kein Bild ausgewählt wurde
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte wähle ein Bild aus!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Gescannte Elemente')),
        body: SingleChildScrollView(
          child: _currentPageIndex == 2 && selectedImage != null
              ? Image.file(selectedImage!) // Zeigt das Bild an
              : _pages[_currentPageIndex], // Zeigt die andere Seite an
        ),
        bottomNavigationBar: CustomNavigationBar(
          currentPageIndex: _currentPageIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentPageIndex = index;
              // Wenn auf die Galerie geklickt wird, öffne den ImagePicker
              if (_currentPageIndex == 2) {
                pickImage(); // Öffnet den ImagePicker
              }
            });
          },
        ),
      ),
    );
  }
}
