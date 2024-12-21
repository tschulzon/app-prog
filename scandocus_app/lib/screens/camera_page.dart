import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scandocus_app/main.dart';
import 'package:scandocus_app/screens/home_page.dart';

import '../screens/ocr_page.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';
import '../screens/image_preview.dart';

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  // final List<CameraDescription> cameras;
  final String? existingFilename;
  final int? newPage;
  final bool? replaceImage;
  final String? existingId;
  final int? existingPage;
  final DocumentSession? session;

  const TakePictureScreen(
      {super.key,
      this.existingFilename,
      this.newPage,
      this.replaceImage,
      this.existingId,
      this.existingPage,
      this.session});

  // final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  DocumentSession currentSession = DocumentSession(fileName: "Neues Dokument");
  // DocumentScannerController? _controller;
  List<String> _pictures = [];
  String imagePath = "";

  bool _isLoading = false;

  File? selectedImage; // Ausgewähltes Bild als Datei
  late String? existingFilename;
  late int? newPage;
  late bool replaceImage = false;
  late String? existingId;
  late int? existingPage;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "Dokument_$formattedDate";
    existingFilename = widget.existingFilename;
    newPage = widget.newPage;
    replaceImage = widget.replaceImage ?? false;
    existingId = widget.existingId;
    existingPage = widget.existingPage;

    if (widget.session != null) {
      currentSession = widget.session!;
    } else {
      currentSession = DocumentSession(fileName: fileName);
    }

    openCameraScanner();
  }

  Future<void> initPlatformState() async {}

  Future<void> openCameraScanner() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pictures = await CunningDocumentScanner.getPictures(
            noOfPages: replaceImage == true ? 1 : 10,
            isGalleryImportAllowed: true,
          ) ??
          [];
      if (!mounted) return;

      if (pictures.isNotEmpty) {
        setState(() {
          if (replaceImage == true) {
            imagePath = pictures[0];
            _pictures = pictures;
          } else {
            _pictures = pictures;
          }
        });
        // imagePath = pictures[0];

        final now = DateTime.now();
        // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
        final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

        if (replaceImage == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OcrProcessView(
                  takenPicture: imagePath,
                  existingFilename: existingFilename,
                  existingId: existingId,
                  replaceImage: replaceImage,
                  existingPage: existingPage),
            ),
          );
        } else {
          for (var picture in _pictures) {
            currentSession.addPage(DocumentPage(
              imagePath: picture,
              captureDate: formatter.format(now),
              pageNumber: currentSession.pages.length + 1,
            ));
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentOverview(
                  session: currentSession,
                  existingFilename: existingFilename,
                  newPage: newPage),
            ),
          );
        }
      } else {
        print("Keine Bilder aufgenommen");
      }
    } catch (exception) {
      // Handle exception here
      print("Fehler beim Öffnen der Kamera: $exception");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: Text(
                      Navigator.canPop(context)
                          ? "Kamera wurde geschlossen.\n\nBitte zurück zur vorherigen Seite gehen."
                          : "Kamera wurde geschlossen.\n\nBitte erneut öffnen oder wieder zur Hauptseite gehen.",
                      style: GoogleFonts.quicksand(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 50),
                  Navigator.canPop(context)
                      ? ElevatedButton(
                          onPressed: () {
                            // Überprüfe, ob es eine Seite gibt, zu der zurückgegangen werden kann
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePictureScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(219, 11, 185,
                                216), // Hintergrundfarbe des Buttons
                            elevation: 15,
                            overlayColor:
                                const Color.fromARGB(255, 26, 255, 114)
                                    .withOpacity(0.7),
                          ),
                          child: Text(
                              Navigator.canPop(context)
                                  ? "Zurück"
                                  : "Kamera öffnen",
                              style: GoogleFonts.quicksand(
                                textStyle: TextStyle(
                                  color: Color(0xFF202124),
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              )),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TakePictureScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(219, 11, 185, 216),
                                elevation: 15,
                                padding: EdgeInsets.all(12),
                                overlayColor:
                                    const Color.fromARGB(255, 26, 255, 114)
                                        .withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Color(0xFF202124),
                                size: 30.0,
                              ),
                            ),
                            SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyApp(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(219, 11, 185, 216),
                                elevation: 15,
                                padding: EdgeInsets.all(12),
                                overlayColor:
                                    const Color.fromARGB(255, 26, 255, 114)
                                        .withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Icon(
                                Icons.house,
                                color: Color(0xFF202124),
                                size: 30.0,
                              ),
                            )
                          ],
                        ),
                ],
              ),
            ),
    );
  }

  void onPressed() async {
    List<String> pictures;
    String imagePath;
    try {
      pictures = await CunningDocumentScanner.getPictures(
            noOfPages: replaceImage == true ? 1 : 10,
            isGalleryImportAllowed: true,
          ) ??
          [];
      if (!mounted) return;
      setState(() {
        if (replaceImage == true) {
          imagePath = pictures[0];
          _pictures = pictures;
        } else {
          _pictures = pictures;
        }
      });
      imagePath = pictures[0];
      final now = DateTime.now();
      // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
      final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
      if (replaceImage == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OcrProcessView(
                takenPicture: imagePath,
                existingFilename: existingFilename,
                existingId: existingId,
                replaceImage: replaceImage,
                existingPage: existingPage),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        for (var picture in _pictures) {
          currentSession.addPage(DocumentPage(
            imagePath: picture,
            captureDate: formatter.format(now),
            pageNumber: currentSession.pages.length + 1,
          ));
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentOverview(
                session: currentSession,
                existingFilename: existingFilename,
                newPage: newPage),
          ),
        );
      }
    } catch (exception) {
      // Handle exception here
      print("FEHLER: ");
      print(exception);
    }
  }
}
