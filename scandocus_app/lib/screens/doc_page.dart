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
  final String? searchTerm;

  const Detailpage({super.key, required this.document, this.searchTerm});

  @override
  State<Detailpage> createState() => _DetailpageState();
}

class _DetailpageState extends State<Detailpage> {
  late Document doc;
  late List<Document> documents = [];
  final String serverUrl = 'http://192.168.178.193:3000';
  // final String serverUrl = 'http://192.168.2.171:3000';
  // final String serverUrl = 'http://192.168.178.49:3000'; //eltern wlan

  late PageController pageController;
  String? searchTerm;

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
    documents = documentProvider.getDocumentsByFileName(doc.fileName);

    //Aktuelle seite zum anzeigen herholen
    currentIndex = documents.indexWhere((d) => d.id == doc.id);

    pageController = PageController(initialPage: currentIndex);

    if (widget.searchTerm != null) {
      searchTerm = widget.searchTerm;
    }
  }

  TextSpan highlightSearchTerm(String text, String? searchTerm) {
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    // Wenn der searchTerm null oder leer ist, gibt es keine Markierung
    if (searchTerm == null || searchTerm.isEmpty) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    if (!originalText.contains(matches)) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    List<TextSpan> textSpans = [];
    int startIndex = 0;

    while (startIndex < text.length) {
      final index = originalText.indexOf(matches, startIndex);
      if (index == -1) {
        textSpans.add(TextSpan(
          text: text.substring(startIndex),
          style: quicksandTextStyle,
        ));
        break;
      }

      // Text vor dem Treffer
      if (index > startIndex) {
        textSpans.add(TextSpan(
          text: text.substring(startIndex, index),
          style: quicksandTextStyle,
        ));
      }

      // Markierter Text
      textSpans.add(
        TextSpan(
          text: text.substring(index, index + searchTerm.length),
          style: quicksandTextStyle.copyWith(
              backgroundColor: Color.fromARGB(255, 60, 221, 121),
              color: Color(0xFF202124),
              fontWeight: FontWeight.bold),
        ),
      );

      startIndex = index + searchTerm.length;
    }

    return TextSpan(children: textSpans);
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
    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text('Seite ${documents[currentIndex].siteNumber}'),
        titleTextStyle: quicksandTextStyleTitle,
        centerTitle: true,
        backgroundColor: baseColor,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(219, 11, 185, 216), // Farbe des Zurück-Pfeils
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
                            width: 300.0, // Feste Breite
                            height: 400.0, // Feste Höhe
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: currentDoc.image.isNotEmpty
                                  ? Image.network(
                                      '$serverUrl${currentDoc.image}',
                                      width: 300,
                                      height: 400,
                                      fit: BoxFit.contain,
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
                                        color:
                                            Color.fromARGB(219, 11, 185, 216),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // SelectableText(
                                  //   currentDoc.docText.join('\n'),
                                  //   textAlign: TextAlign.center,
                                  //   style: quicksandTextStyle,
                                  // ),
                                  SelectableText.rich(
                                    TextSpan(
                                      children: [
                                        highlightSearchTerm(
                                          currentDoc.docText
                                              .join(' ')
                                              .replaceAll('\n', ' '),
                                          searchTerm,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  )
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
      bottomNavigationBar:
          BottomButtons(page: documents[currentIndex], documents: documents),
    );
  }
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.page, required this.documents});
  final List<Document> documents;

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
                  // final documentProvider =
                  //     Provider.of<DocumentProvider>(context, listen: false);

                  documents.removeWhere((page) => page.id == this.page.id);
                  await apiService.deleteDocFromSolr(page.id, page.fileName);

                  final SnackBar snackBar = SnackBar(
                    content: const Text('Dokument wurde gelöscht!'),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    for (int i = 0; i < documents.length; i++) {
                      documents[i].siteNumber = i + 1;
                    }

                    Navigator.pop(context, documents);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
