import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scandocus_app/screens/image_preview.dart';

import '../screens/ocr_page.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';

// A screen that allows users to take a picture using a given camera.
class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  UploadImageScreenState createState() => UploadImageScreenState();
}

class UploadImageScreenState extends State<UploadImageScreen> {
  DocumentSession currentSession = DocumentSession(fileName: "Neues Dokument");
  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "Dokument_$formattedDate";

    currentSession = DocumentSession(fileName: fileName);
  }

  // Methode zum Auswählen eines Bildes
  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery); // Bild aus Galerie auswählen
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          // navigateToOCRScreen();
        });
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(
                  capturedImage: image.path, session: currentSession),
            ),
          );
        }
      }
    } catch (e) {
      print("Fehler beim Upload Fenster.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aus Galerie hochladen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Bitte ein Bild aus der Galerie auswählen."),
            SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () async {
                pickImage();
              },
              label: Text("Hochladen"),
              icon: Icon(Icons.perm_media),
            ),
          ],
        ),
      ),
    );
  }
}
