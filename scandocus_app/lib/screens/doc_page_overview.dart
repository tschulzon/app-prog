import 'package:flutter/material.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'dart:io';

import '../models/document.dart';

class DocumentPageOvereview extends StatefulWidget {
  final List<Document> documents; // Liste der Dokumente mit demselben fileName
  final String fileName; // Name der Datei (optional)

  const DocumentPageOvereview({
    super.key,
    required this.documents,
    required this.fileName,
  });

  @override
  State<DocumentPageOvereview> createState() => _DocumentPageOvereviewState();
}

class _DocumentPageOvereviewState extends State<DocumentPageOvereview> {
  late List<Document> documents;

  Future<void> navigateToDetailPage(BuildContext context, int index) async {
    final updatedDocuments = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Detailpage(
          document: widget.documents[index],
          documents: widget.documents,
        ),
      ),
    );

    // Falls die Detailseite die Liste zurückgibt, aktualisiere sie
    if (updatedDocuments != null) {
      setState(() {
        documents = updatedDocuments;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
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
          itemCount: widget.documents.length + 1, // Anzahl der Seiten
          itemBuilder: (context, index) {
            if (index < widget.documents.length) {
              final doc = widget.documents[index];
              // final String imageUrl = 'http://192.168.178.193:3000${doc.image}';
              final String imageUrl = 'http://192.168.2.171:3000${doc.image}';

              return GestureDetector(
                onTap: () {
                  // Aktion beim Klick auf das Bild
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) =>
                  //             Detailpage(document: doc, documents: widget.documents)));
                  navigateToDetailPage(context, index);
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
                              ? Image.network(
                                  imageUrl,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                    return const Icon(Icons.error);
                                  },
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Seite ${index + 1}'),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePictureScreen(),
                                ),
                              );
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
