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
import 'package:camera/camera.dart';

import '../screens/ocr_page.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TakePictureScreen(
      {super.key, required this.camera, required this.cameras});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? selectedImage; // Ausgewähltes Bild als Datei

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
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
    _controller.dispose();
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
                final double previewRatio = _controller.value.aspectRatio;

                return OverflowBox(
                  maxWidth: screenRatio > previewRatio
                      ? constraints.maxWidth
                      : constraints.maxHeight * previewRatio,
                  maxHeight: screenRatio > previewRatio
                      ? constraints.maxWidth / previewRatio
                      : constraints.maxHeight,
                  child: CameraPreview(_controller),
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
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            print('Kamera wird initialisiert...');
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            print('Versuche, ein Bild aufzunehmen...');
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            // If the picture was taken, display it on a new screen.
            print('Bild aufgenommen: ${image.path}');
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OcrProcessView(
                  cameras: widget.cameras,
                  takenPicture: image.path,
                ),
              ),
            );
          } catch (e) {
            // Fehlerbehandlung, wenn ein Problem beim Aufnehmen des Bildes auftritt
            print("Fehler beim Aufnehmen des Bildes: $e");
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
