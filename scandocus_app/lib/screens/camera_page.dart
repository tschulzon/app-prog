import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

import '../screens/ocr_page.dart';
import '../screens/docsession.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  // final List<CameraDescription> cameras;

  const TakePictureScreen({super.key});

  // final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  DocumentSession currentSession = DocumentSession(fileName: "Neues Dokument");
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  File? selectedImage; // Ausgewähltes Bild als Datei

  @override
  void initState() {
    super.initState();
    _setupCamera();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "Dokument_$formattedDate";

    currentSession = DocumentSession(fileName: fileName);
  }

  Future<void> _setupCamera() async {
    try {
      // Lade die Liste der verfügbaren Kameras
      final cameras = await availableCameras();

      if (cameras.isNotEmpty) {
        // Wähle die erste Kamera (Rückkamera) aus
        final camera = cameras.first;

        // Initialisiere den Controller
        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
        );

        // Initialisiere die Kamera
        _initializeControllerFuture = _controller!.initialize();
        setState(() {}); // Aktualisiere den Zustand
      } else {
        print('Keine Kameras verfügbar.');
      }
    } catch (e) {
      print('Fehler beim Laden der Kamera: $e');
    }
  }

  // Navigiere zum OCR-Prozess-Bildschirm und übergebe das Bild
  void navigateToOCRScreen() {
    if (selectedImage != null) {
      Navigator.push(
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
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokument aufnehmen')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //Make CameraPreview Fullscreen on every Device
            return LayoutBuilder(
              builder: (context, constraints) {
                final double screenRatio =
                    constraints.maxWidth / constraints.maxHeight;
                final double previewRatio = _controller!.value.aspectRatio;

                return OverflowBox(
                  maxWidth: screenRatio > previewRatio
                      ? constraints.maxWidth
                      : constraints.maxHeight * previewRatio,
                  maxHeight: screenRatio > previewRatio
                      ? constraints.maxWidth / previewRatio
                      : constraints.maxHeight,
                  child: CameraPreview(_controller!),
                );
              },
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          if (_controller != null) {
            try {
              // Ensure that the camera is initialized.
              print('Kamera wird initialisiert...');
              await _initializeControllerFuture;

              // Attempt to take a picture and get the file `image`
              // where it was saved.
              print('Versuche, ein Bild aufzunehmen...');
              final image = await _controller!.takePicture();

              if (!context.mounted) return;

              // If the picture was taken, display it on a new screen.
              print('Bild aufgenommen: ${image.path}');
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(
                      capturedImage: image.path, session: currentSession),
                ),
              );
            } catch (e) {
              // Fehlerbehandlung, wenn ein Problem beim Aufnehmen des Bildes auftritt
              print("Fehler beim Aufnehmen des Bildes: $e");
            }
          }
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String capturedImage;
  final DocumentSession session;

  const DisplayPictureScreen({
    super.key,
    required this.capturedImage,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    child: Image.file(File(capturedImage))),
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Dokument verwerfen',
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Navigator.pop(context); // Zurück zur Kamera
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Dokument verwenden',
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        session.addPage(DocumentPage(
                          imagePath: capturedImage,
                          captureDate: "2024-11-24T10:00:00Z",
                          pageNumber: session.pages.length + 1,
                        ));
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DocumentOverview(session: session),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Weiteres Dokument aufnehmen',
                      icon: const Icon(Icons.plus_one),
                      onPressed: () {
                        session.addPage(DocumentPage(
                          imagePath: capturedImage,
                          captureDate: "2024-11-24T10:00:00Z",
                          pageNumber: session.pages.length + 1,
                        ));
                        Navigator.pop(context);
                      },
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
