import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';

import '../widgets/language_list.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';
import '../models/document_session.dart';

class DocumentSessionScreen extends StatefulWidget {
  @override
  DocumentSessionScreenState createState() => DocumentSessionScreenState();
}

class DocumentSessionScreenState extends State<DocumentSessionScreen> {
  DocumentSession session = DocumentSession(fileName: "Neues Dokument");

  void addPage(String imagePath) {
    setState(() {
      session.addPage(DocumentPage(
        imagePath: imagePath,
        captureDate: "2024-11-24T10:00:00Z",
        pageNumber: session.pages.length + 1,
      ));
    });
  }

  void scanText(int pageIndex) {
    // Logik für OCR-Scan hier einfügen
    print("Scanne Text für Seite ${pageIndex + 1}");
  }

  void saveDocument() {
    // Logik zum Speichern des Dokuments (z.B. an Solr senden)
    print("Dokument gespeichert mit ${session.pages.length} Seiten.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.fileName),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              print("test");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: session.pages.length,
              itemBuilder: (context, index) {
                DocumentPage page = session.pages[index];
                return ListTile(
                  leading:
                      Image.file(File(page.imagePath), width: 50, height: 50),
                  title: Text("Seite ${index + 1}"),
                  subtitle: Text("Aufgenommen am ..."),
                  trailing: IconButton(
                    icon: Icon(Icons.text_snippet),
                    onPressed: () => scanText(index),
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Logik, um eine neue Seite zu fotografieren
              String newImagePath = await captureImage();
              addPage(newImagePath);
            },
            icon: Icon(Icons.camera),
            label: Text("Seite hinzufügen"),
          ),
        ],
      ),
    );
  }

  Future<String> captureImage() async {
    // Öffne die Kamera und gib den Bildpfad zurück
    // Beispiel mit einem Dummy-Bildpfad:
    return "/path/to/captured/image.jpg";
  }
}
