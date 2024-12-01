import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/image_preview.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import '../utils/document_provider.dart';

import '../models/document.dart';

class DocumentPageOvereview extends StatefulWidget {
  final String fileName; // Name der Datei (optional)

  const DocumentPageOvereview({
    super.key,
    required this.fileName,
  });

  @override
  State<DocumentPageOvereview> createState() => _DocumentPageOvereviewState();
}

class _DocumentPageOvereviewState extends State<DocumentPageOvereview> {
  File? selectedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dokumente beim Betreten der Seite aktualisieren
    Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        final documents =
            documentProvider.getDocumentsByFileName(widget.fileName);
        // Sortieren der Dokumente nach `pageNumber`
        documents.sort((a, b) => a.siteNumber.compareTo(b.siteNumber));
        final numberDocuments = documents.length;

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
              itemCount: documents.length + 1, // Anzahl der Seiten
              itemBuilder: (context, index) {
                if (index < documents.length) {
                  final doc = documents[index];
                  final String imageUrl =
                      'http://192.168.178.193:3000${doc.image}'; //home wlan
                  // final String imageUrl = 'http://192.168.2.171:3000${doc.image}'; //cathy wlan
                  // final String imageUrl =
                  //     'http://192.168.178.49:3000${doc.image}'; //eltern wlan

                  return GestureDetector(
                    onTap: () async {
                      // Navigate to detail page and await the result
                      final updatedDocuments = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detailpage(document: doc),
                        ),
                      );

                      // If the detail page returns updated documents, update the provider
                      if (updatedDocuments != null) {
                        documentProvider.setDocuments(updatedDocuments);
                      }
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TakePictureScreen(
                                        existingFilename: widget.fileName,
                                        newPage: numberDocuments + 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.upload_file),
                                title: Text("Aus Galerie hochladen"),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UploadImageScreen(
                                        existingFilename: widget.fileName,
                                        newPage: numberDocuments + 1,
                                      ),
                                    ),
                                  );
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
      },
    );
  }
}
