import 'package:flutter/material.dart';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';

import '../widgets/language_list.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';

class OcrProcessView extends StatefulWidget {
  // final List<CameraDescription> cameras;

  final File? selectedImage; // Ausgewähltes Bild als Datei
  final String? takenPicture;

  const OcrProcessView(
      {super.key,
      this.selectedImage,
      // required this.cameras,
      this.takenPicture});

  @override
  State<OcrProcessView> createState() => _OcrProcessViewState();
}

class _OcrProcessViewState extends State<OcrProcessView> {
  late File? selectedImage; // Ausgewähltes Bild als Datei
  late String? takenPicture;
  var showText = "Hier wird Text angezeigt";
  String selectedLanguage = "eng";

  bool isDownloading = false;
  bool isScanning = false;
  bool scanningDone = false;

  @override
  void initState() {
    super.initState();
    selectedImage =
        widget.selectedImage; // Das Bild aus dem Widget-Parameter setzen

    takenPicture = widget.takenPicture;
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LanguageList(
              currentLanguage: selectedLanguage,
              languageSelected: (newLang) {
                setState(() {
                  selectedLanguage = newLang.code;
                });
              }),
        );
      },
    );
  }

  // Methode für die OCR-Erkennung
  Future<void> performOCR() async {
    String? imagePath;
    setState(() {
      isScanning = true; //activate
      scanningDone = false;
    });

    // Überprüfen, ob `selectedImage` oder `takenPicture` nicht null sind
    if (selectedImage != null) {
      imagePath = selectedImage!
          .path; // Wenn `selectedImage` nicht null ist, verwenden wir diesen Pfad
    } else if (takenPicture != null) {
      imagePath =
          takenPicture!; // Wenn `takenPicture` nicht null ist, verwenden wir diesen Pfad
    } else {
      print("Kein Bild zum Extrahieren vorhanden!");
      setState(() {
        showText = "Kein Bild zum Extrahieren vorhanden!";
      });
      return; // Beenden, wenn kein Bild vorhanden ist
    }

    try {
      print("OCR wird ausgeführt...");
      String extractedText = await FlutterTesseractOcr.extractText(
        imagePath, // Pfad zum ausgewählten Bild
        language: selectedLanguage,
      );

      // Aktualisiere den Status
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = extractedText;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = "Fehler bei der OCR-Erkennung: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR-Verarbeitung"), leading: null),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                selectedImage != null && takenPicture == null
                    ? Image.file(
                        selectedImage!) // Das ausgewählte Bild anzeigen
                    : (selectedImage == null && takenPicture != null
                        ? Image.file(File(
                            takenPicture!)) // Das aufgenommene Bild anzeigen
                        : Text("Kein Bild ausgewählt!")),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          print("Sprachbutton gedrückt");
                          _showLanguageDialog(context);
                        },
                        icon: const Icon(Icons.language),
                        label: Text(selectedLanguage),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: performOCR,
                        child: Text("Text scannen"),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: isScanning,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text('Text wird erkannt...'),
                          SizedBox(height: 10),
                          ProgressIndicatorExample(),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: scanningDone,
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            showText, // Text anzeigen
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => HomePage(cameras: widget.cameras),
                          //   ),
                          // );
                          // Dynamische Prüfungen und Fallback-Logik
                          // await apiService.testConnection();
                          ApiService apiService = ApiService();
                          await apiService.sendDataToServer(
                            'example.txt',
                            'Dies ist ein Testdokument.',
                            language: 'de',
                            scanDate: '2024-11-24T10:00:00Z',
                          );

                          print("Speichernbutton gedrückt");
                        },
                        icon: const Icon(Icons.save),
                        label: Text("Speichern"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
