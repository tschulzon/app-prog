import 'package:flutter/material.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'dart:io';

import '../models/document.dart';

class DocumentPageOvereview extends StatelessWidget {
  final List<Document> documents; // Liste der Dokumente mit demselben fileName
  final String fileName; // Name der Datei (optional)

  const DocumentPageOvereview({
    super.key,
    required this.documents,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 Spalten
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: documents.length + 1, // Anzahl der Seiten
          itemBuilder: (context, index) {
            if (index < documents.length) {
              final doc = documents[index];

              return GestureDetector(
                onTap: () {
                  // Aktion beim Klick auf das Bild
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Detailpage(document: doc)));
                },
                child: SizedBox(
                  width: 100,
                  height: 400,
                  child: Card(
                    elevation: 4.0,
                    child: Column(
                      children: [
                        // Bild anzeigen
                        Expanded(
                          child: doc.image.isNotEmpty
                              ? Image.asset(
                                  doc.image, // Der Pfad zum Bild
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                    return const Icon(Icons.error);
                                  },
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Seite ${doc.siteNumber}'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.camera),
                            title: Text("Foto aufnehmen"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.upload_file),
                            title: Text("Aus Galerie hochladen"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.text_snippet),
                            title: Text("Text hinzufügen"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  color: Colors.grey[200],
                  elevation: 4.0,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 40.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
