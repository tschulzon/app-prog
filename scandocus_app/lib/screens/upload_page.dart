import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scandocus_app/screens/image_preview.dart';

import '../screens/ocr_page.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

// A screen that allows users to take a picture using a given camera.
class UploadImageScreen extends StatefulWidget {
  final String? existingFilename;
  final int? newPage;
  final bool? replaceImage;
  final String? existingId;
  final int? existingPage;

  const UploadImageScreen(
      {super.key,
      this.existingFilename,
      this.newPage,
      this.replaceImage,
      this.existingId,
      this.existingPage});

  @override
  UploadImageScreenState createState() => UploadImageScreenState();
}

class UploadImageScreenState extends State<UploadImageScreen> {
  DocumentSession currentSession = DocumentSession(fileName: "Neues Dokument");
  File? selectedImage;
  final ImagePicker picker = ImagePicker();
  late String? existingFilename;
  late int? newPage;
  late bool? replaceImage;
  late String? existingId;
  late int? existingPage;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "Dokument_$formattedDate";

    currentSession = DocumentSession(fileName: fileName);
    existingFilename = widget.existingFilename;
    newPage = widget.newPage;
    replaceImage = widget.replaceImage;
    existingId = widget.existingId;
    existingPage = widget.existingPage;
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
                capturedImage: image.path,
                session: currentSession,
                existingFilename: existingFilename,
                newPage: newPage,
                replaceImage: replaceImage,
                existingId: existingId,
                existingPage: existingPage,
              ),
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
    Color baseColor = Color(0xFF202124);
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleButton = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: Color(0xFF202124),
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
      ),
    );

    return Scaffold(
      backgroundColor: baseColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Bitte ein Bild aus der Galerie auswählen.",
                style: quicksandTextStyleTitle),
            SizedBox(height: 50),
            ClayContainer(
              depth: 5,
              spread: 5,
              surfaceColor: Color.fromARGB(219, 11, 185, 216),
              width: 220,
              color: baseColor,
              borderRadius: 30,
              child: GestureDetector(
                onTap: () async {
                  pickImage();
                },
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.perm_media, color: Color(0xFF202124)),
                        const SizedBox(width: 10.0),
                        Text("Hochladen", style: quicksandTextStyleButton)
                      ],
                    )),
              ),
            ),
            // ElevatedButton.icon(
            //   onPressed: () async {
            //     pickImage();
            //   },
            //   label: Text("Hochladen"),
            //   icon: Icon(Icons.perm_media),
            // ),
          ],
        ),
      ),
    );
  }
}
