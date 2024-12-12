import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

import '../screens/ocr_page.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String capturedImage;
  final DocumentSession? session;
  final String? existingFilename;
  final int? newPage;
  final bool? replaceImage;
  final String? existingId;
  final int? existingPage;

  const DisplayPictureScreen({
    super.key,
    required this.capturedImage,
    this.session,
    this.existingFilename,
    this.newPage,
    this.replaceImage,
    this.existingId,
    this.existingPage,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Vorschau'),
        titleTextStyle: GoogleFonts.quicksand(
          textStyle: TextStyle(
            color: Color.fromARGB(219, 11, 185, 216),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: baseColor,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(219, 11, 185, 216), // Farbe des Zurück-Pfeils
        ),
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClayContainer(
                  depth: 13,
                  spread: 5,
                  color: baseColor,
                  borderRadius: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child:
                            Image.file(File(capturedImage), fit: BoxFit.cover)),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ClayContainer(
                    depth: 10,
                    spread: 10,
                    color: baseColor,
                    borderRadius: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(219, 11, 185, 216),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        color: baseColor,
                        tooltip: 'Dokument verwerfen',
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          Navigator.pop(context); // Zurück zur Kamera
                        },
                      ),
                    ),
                  ),
                  ClayContainer(
                    depth: 10,
                    spread: 10,
                    color: baseColor,
                    borderRadius: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(219, 11, 185, 216),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        color: baseColor,
                        tooltip: 'Dokument verwenden',
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          final now = DateTime.now();
                          // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
                          final formatter =
                              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
                          if (replaceImage != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OcrProcessView(
                                    takenPicture: capturedImage,
                                    existingFilename: existingFilename,
                                    existingId: existingId,
                                    replaceImage: replaceImage,
                                    existingPage: existingPage),
                              ),
                            );
                          } else {
                            session!.addPage(DocumentPage(
                              imagePath: capturedImage,
                              captureDate: formatter.format(now),
                              pageNumber: session!.pages.length + 1,
                            ));

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentOverview(
                                    session: session!,
                                    existingFilename: existingFilename,
                                    newPage: newPage),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  ClayContainer(
                    depth: 10,
                    spread: 10,
                    color: baseColor,
                    borderRadius: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(219, 11, 185, 216),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        color: baseColor,
                        tooltip: 'Weiteres Dokument aufnehmen',
                        icon: const Icon(Icons.plus_one),
                        onPressed: () {
                          final now = DateTime.now();
                          // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
                          final formatter =
                              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
                          session!.addPage(DocumentPage(
                            imagePath: capturedImage,
                            captureDate: formatter.format(now),
                            pageNumber: session!.pages.length + 1,
                          ));
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
