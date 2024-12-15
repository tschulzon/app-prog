import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';
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

  late PageController pageController;
  int currentIndex = 0;

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

    //Nach Seitennummer sortieren
    documentProvider.documents
        .sort((a, b) => a.siteNumber.compareTo(b.siteNumber));

    //alle Seiten des Dokuments anhand des filenames bekommen
    final documents = documentProvider.getDocumentsByFileName(doc.fileName);

    //Aktuelle seite zum anzeigen herholen
    currentIndex = documents.indexWhere((d) => d.id == doc.id);

    pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        // Hier holst du die Liste der Dokumente
        final documents = documentProvider.getDocumentsByFileName(doc.fileName);

        return Scaffold(
          backgroundColor: baseColor,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: Text('Seite ${documents[currentIndex].siteNumber}'),
            titleTextStyle: quicksandTextStyleTitle,
            centerTitle: true,
            backgroundColor: baseColor,
            iconTheme: const IconThemeData(
              color:
                  Color.fromARGB(219, 11, 185, 216), // Farbe des Zurück-Pfeils
            ),
          ),
          body: documents.isNotEmpty
              ? PageView.builder(
                  controller: pageController,
                  itemCount: documents.length,
                  onPageChanged: (pageIndex) {
                    // Wenn der Benutzer die Seite wechselt, kannst du den AppBar-Titel aktualisieren
                    setState(() {
                      currentIndex = pageIndex;
                    });
                  },
                  itemBuilder: (context, index) {
                    final currentDoc = documents[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            children: [
                              ClayContainer(
                                depth: 13,
                                spread: 5,
                                color: baseColor,
                                borderRadius: 20,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: currentDoc.image.isNotEmpty
                                      ? Image.network(
                                          '$serverUrl${currentDoc.image}',
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.error);
                                          },
                                        )
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              ClayContainer(
                                depth: 13,
                                spread: 5,
                                color: baseColor,
                                borderRadius: 20,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Erkannter Text: ",
                                        style: GoogleFonts.quicksand(
                                          textStyle: TextStyle(
                                            color: Color.fromARGB(
                                                219, 11, 185, 216),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        currentDoc.docText.join('\n'),
                                        textAlign: TextAlign.center,
                                        style: quicksandTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text('Keine Dokumente vorhanden.'),
                ),
          bottomNavigationBar: BottomButtons(page: documents[currentIndex]),
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

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 70.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                color: Color(0xFF202124),
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
          ),
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                color: Color(0xFF202124),
                tooltip: 'Dokument ersetzen',
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: Color(0xFF202124),
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              "Seite ersetzen",
                              style: GoogleFonts.quicksand(
                                textStyle: TextStyle(
                                  color: Color.fromARGB(219, 11, 185, 216),
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.camera),
                            title: Text("Foto aufnehmen",
                                style: quicksandTextStyleTitle),
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
                            title: Text("Aus Galerie hochladen",
                                style: quicksandTextStyleTitle),
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
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                color: Color(0xFF202124),
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
          ),
        ],
      ),
    );
  }
}
