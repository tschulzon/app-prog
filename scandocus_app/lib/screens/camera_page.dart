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
  late bool? replaceImage;
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
    replaceImage = widget.replaceImage;
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
            noOfPages: replaceImage != null ? 1 : 10,
            isGalleryImportAllowed: true,
          ) ??
          [];
      if (!mounted) return;

      if (pictures.isNotEmpty) {
        setState(() {
          if (replaceImage != null) {
            imagePath = pictures[0];
          } else {
            _pictures = pictures;
          }
        });
        // imagePath = pictures[0];

        final now = DateTime.now();
        // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
        final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

        if (replaceImage != null) {
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

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentOverview(
                  session: currentSession,
                  existingFilename: existingFilename,
                  newPage: newPage),
            ),
            (Route<dynamic> route) => false,
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), // Versteckt die AppBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0, // Setzt die AppBar auf unsichtbar
        ),
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                // Prüfe hier die Bedingung, z.B., keine Bilder aufgenommen
                if (_pictures.isEmpty) {
                  // Navigation zur anderen Seite auslösen
                  Future.microtask(() {
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyApp(),
                        ),
                      );
                    }
                  });
                }

                // UI anzeigen, wenn Bilder vorhanden sind
                return Center(
                  child: Text("Keine Bilder aufgenommen."),
                );
              },
            ),
    );
  }

  void onPressed() async {
    List<String> pictures;
    String imagePath;
    try {
      pictures = await CunningDocumentScanner.getPictures(
            noOfPages: replaceImage != null ? 1 : 10,
            isGalleryImportAllowed: true,
          ) ??
          [];
      if (!mounted) return;
      setState(() {
        if (replaceImage != null) {
          imagePath = pictures[0];
        } else {
          _pictures = pictures;
        }
      });
      imagePath = pictures[0];
      final now = DateTime.now();
      // Format: YYYY-MM-DDTHH:mm:ss.SSSZ
      final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
      if (replaceImage != null) {
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

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentOverview(
                session: currentSession,
                existingFilename: existingFilename,
                newPage: newPage),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (exception) {
      // Handle exception here
      print("FEHLER: ");
      print(exception);
    }
  }
}
