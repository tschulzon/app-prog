import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import '../models/document.dart';
import '../screens/ocr_page.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/camera_page.dart';
import '../services/api_service.dart';
import '../utils/document_provider.dart';

class Detailpage extends StatefulWidget {
  final Document document;
  // final List<Document> documents;

  const Detailpage({super.key, required this.document});

  @override
  State<Detailpage> createState() => _DetailpageState();
}

class _DetailpageState extends State<Detailpage> {
  late Document doc;
  final String serverUrl = 'http://192.168.178.193:3000';
  // final String serverUrl = 'http://192.168.2.171:3000';
  // final String serverUrl = 'http://192.168.178.49:3000'; //eltern wlan

  @override
  void initState() {
    super.initState();

    // Lade das Dokument aus dem Provider, falls es aktualisiert wurde
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);
    doc = documentProvider.documents.firstWhere(
      (d) => d.id == widget.document.id,
      orElse: () => widget.document, // Falls das Dokument nicht gefunden wird
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        //Aktuellste Version von Dokument holen
        final currentDoc = documentProvider.documents.firstWhere(
          (d) => d.id == doc.id,
          orElse: () => doc, // Fallback auf lokale Kopie
        );
        return Scaffold(
          appBar: AppBar(
            title: Text('Seite ${currentDoc.siteNumber}'),
          ),
          body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
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
                          child: doc.image.isNotEmpty
                              ? Image.network(
                                  '$serverUrl${currentDoc.image}',
                                  errorBuilder: (context, error, stackTrace) {
                                    // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                    return const Icon(Icons.error);
                                  },
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Erkannter Text: "),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            currentDoc.docText.join('\n'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ),
          bottomNavigationBar: BottomButtons(page: currentDoc),
        );
      },
    );
  }
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.page});
  // final List<Document> documents;

  final Document page;

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 70.0,
      child: Row(
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
              tooltip: 'Dokument nochmal scannen',
              icon: const Icon(Icons.document_scanner),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OcrProcessView(
                        existingImage: page.image,
                        existingFilename: page.fileName,
                        existingId: page.id,
                        existingPage: page.siteNumber),
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
              tooltip: 'Dokument ersetzen',
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text("Seite ersetzen"),
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.camera),
                          title: Text("Foto aufnehmen"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakePictureScreen(
                                  existingFilename: page.fileName,
                                  replaceImage: true,
                                  existingId: page.id,
                                  existingPage: page.siteNumber,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.perm_media),
                          title: Text("Aus Galerie hochladen"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadImageScreen(
                                  existingFilename: page.fileName,
                                  replaceImage: true,
                                  existingId: page.id,
                                  existingPage: page.siteNumber,
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
              tooltip: 'Seite löschen',
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final documentProvider =
                    Provider.of<DocumentProvider>(context, listen: false);

                await apiService.deleteDocFromSolr(page.id, page.fileName);

                documentProvider.removeDocument(page.id);

                // Dokumentliste aktualisieren
                await documentProvider.fetchDocuments();

                final SnackBar snackBar = SnackBar(
                  content: const Text('Dokument wurde gelöscht!'),
                );

                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
