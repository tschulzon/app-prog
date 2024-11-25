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

class DocumentOverview extends StatelessWidget {
  final DocumentSession session;

  const DocumentOverview({super.key, required this.session});

  Future<void> sendDataToSolr() async {
    try {
      print("Session Data");
      print(session);
      // Textdaten und Bild-URL an Solr senden
      final apiService = ApiService();
      for (var page in session.pages) {
        saveImageLocal(page.imagePath);

        await apiService.sendDataToServer(
          session.fileName,
          page.scannedText, // Text aus OCR
          language: page.language,
          // scanDate: page.captureDate.toIso8601String(),
          scanDate: "2024-11-24T10:00:00Z",
          imageUrl: page.imagePath,
          pageNumber: page.pageNumber,
        );
      }
      print("Dokument gespeichert!");

      print('Daten erfolgreich an Solr gesendet.');
    } catch (e) {
      print('Fehler beim Speichern und Senden: $e');
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
          Expanded(
            child: ListView.builder(
              itemCount: session.pages.length,
              itemBuilder: (context, index) {
                final page = session.pages[index];

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
                  child: Card(
                    child: ListTile(
                      leading: Image.file(
                        File(page.imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text("Seite ${index + 1}"),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              sendDataToSolr();
              // Zurück zur Startseite
              Navigator.popUntil(context, (route) => route.isFirst);
              // Speichern und API-Aufruf
              // final apiService = ApiService();
              // for (var page in session.pages) {
              //   await apiService.sendDataToServer(
              //     session.fileName,
              //     "", // Text wird in einer späteren OCR verarbeitet
              //     language: "eng",
              //     scanDate: page.captureDate.toIso8601String(),
              //     imageUrl: page.imagePath,
              //   );
              // }
              // print("Dokument gespeichert!");

              // Zurück zur Startseite
              // Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: Icon(Icons.save),
            label: Text("Dokument speichern"),
          ),
        ],
      ),
    );
  }
}
