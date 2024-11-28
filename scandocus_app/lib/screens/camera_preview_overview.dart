import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'package:scandocus_app/screens/ocr_page.dart';
import 'dart:io';

import '../models/document.dart';
import '../screens/camera_page.dart';
import '../models/document_session.dart';
import '../screens/ocr_page.dart';
import '../services/api_service.dart';
import '../screens/home_page.dart';

class DocumentOverview extends StatefulWidget {
  final DocumentSession session;

  const DocumentOverview({super.key, required this.session});

  @override
  State<DocumentOverview> createState() => _DocumentOverviewState();
}

class _DocumentOverviewState extends State<DocumentOverview> {
  late TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    // Initialisiere den Controller mit dem Standardnamen
    _fileNameController = TextEditingController(text: widget.session.fileName);
  }

  @override
  void dispose() {
    // Entferne den Controller, um Speicherlecks zu vermeiden
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> sendDataToSolr() async {
    try {
      print("Session Data");
      print(widget.session);
      // Textdaten und Bild-URL an Solr senden
      final apiService = ApiService();
      for (var page in widget.session.pages) {
        // Bild hochladen und Pfad erhalten
        final imagePath = await apiService.uploadImage(File(page.imagePath));

        await apiService.sendDataToServer(
          widget.session.fileName,
          page.scannedText, // Text aus OCR
          language: page.language,
          // scanDate: page.captureDate.toIso8601String(),
          scanDate: page.captureDate,
          imageUrl: imagePath,
          pageNumber: page.pageNumber,
        );
      }
      print("Dokument gespeichert!");

      print('Daten erfolgreich an Solr gesendet.');
    } catch (e) {
      print('Fehler beim Speichern und Senden: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  Future<void> saveImageLocal(String imagePath) async {
    final File imageFile = File(imagePath);

    // Bild lokal speichern
    final directory =
        await getApplicationDocumentsDirectory(); //Pfad vom Anwenderverzeichnis holen
    // Erstelle den Ordnerpfad
    final folderPath = '${directory.path}/Scan2Doc';

    // Überprüfe, ob der Ordner existiert, und erstelle ihn, falls nicht
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true); // Ordner erstellen
      print('Ordner erstellt: $folderPath');
    } else {
      print('Ordner existiert bereits: $folderPath');
    }

    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '$folderPath/$fileName';
    await imageFile.copy(filePath);

    print('Bild erfolgreich gespeichert: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dokumentübersicht")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                labelText: "Dokumentname",
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) {
                // Aktualisiere den Dokumentnamen, wenn der Benutzer etwas eingibt
                setState(() {
                  widget.session.fileName = _fileNameController.text;
                });
                print("NEUER NAME?");
                print(widget.session.fileName);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 Spalten
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: widget.session.pages.length,
              itemBuilder: (context, index) {
                final page = widget.session.pages[index];

                return GestureDetector(
                  onTap: () async {
                    // Navigiere zur OCR-Seite und aktualisiere den Text
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OcrProcessView(
                          selectedImage: File(page.imagePath),
                        ),
                      ),
                    );

                    if (result != null && result is Map) {
                      page.scannedText = result['scannedText'] ?? "";
                      page.language = result['selectedLanguage'] ?? "eng";
                    }
                  },
                  child: SizedBox(
                    width: 100,
                    height: 500,
                    child: Card(
                      elevation: 4.0,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.file(
                              File(page.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Seite ${index + 1}"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     sendDataToSolr();
          //     // Zurück zur Startseite
          //     Navigator.popUntil(context, (route) => route.isFirst);
          //     // Speichern und API-Aufruf
          //     // final apiService = ApiService();
          //     // for (var page in session.pages) {
          //     //   await apiService.sendDataToServer(
          //     //     session.fileName,
          //     //     "", // Text wird in einer späteren OCR verarbeitet
          //     //     language: "eng",
          //     //     scanDate: page.captureDate.toIso8601String(),
          //     //     imageUrl: page.imagePath,
          //     //   );
          //     // }
          //     // print("Dokument gespeichert!");

          //     // Zurück zur Startseite
          //     // Navigator.popUntil(context, (route) => route.isFirst);
          //   },
          //   icon: Icon(Icons.save),
          //   label: Text("Dokument speichern"),
          // ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(50.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            await sendDataToSolr();
          },
          icon: Icon(Icons.save),
          label: Text("Dokument speichern"),
        ),
      ),
    );
  }
}
