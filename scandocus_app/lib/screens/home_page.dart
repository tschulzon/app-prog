import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

import '../widgets/documents_view.dart';
import '../widgets/custom_navigation_bar.dart';
import '../screens/ocr_page.dart';
import '../screens/camera_page.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraDescription selectedCamera;
  int _currentPageIndex = 0;
  String searchQuery = "";

  var showText = "Hier wird Text angezeigt";

  File? selectedImage; // Ausgewähltes Bild als Datei
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      selectedCamera =
          widget.cameras.first; // Wähle die erste Kamera als Standard
    }
  }

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

  // Navigiere zum OCR-Prozess-Bildschirm und übergebe das Bild
  void navigateToOCRScreen() {
    if (selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OcrProcessView(
              selectedImage: selectedImage, cameras: widget.cameras),
        ),
      ).then((value) {
        // Wenn zurückgekehrt wird (z. B. nach OCR oder der Kamera), setzen wir den Index auf 0 zurück
        setState(() {
          _currentPageIndex = 0;
        });
      });
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
          child: DocumentsView(), // Zeigt die andere Seite an
        ),
        bottomNavigationBar: CustomNavigationBar(
          currentPageIndex: _currentPageIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentPageIndex = index;
              // Wenn auf die Galerie geklickt wird, öffne den ImagePicker
              if (_currentPageIndex == 2) {
                pickImage(); // Öffnet den ImagePicker
              } else if (_currentPageIndex == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakePictureScreen(
                      camera: selectedCamera,
                      cameras: widget.cameras,
                    ),
                  ),
                ).then((value) {
                  // Wenn zurückgekehrt wird (z. B. nach OCR oder der Kamera), setzen wir den Index auf 0 zurück
                  setState(() {
                    _currentPageIndex = 0;
                  });
                });
              }
            });
          },
        ),
      ),
    );
  }
}
