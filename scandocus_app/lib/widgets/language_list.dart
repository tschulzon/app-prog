import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/models/document.dart';
import 'package:scandocus_app/utils/document_provider.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/lang_options.dart';
import '../widgets/progress_bar.dart';

class LanguageList extends StatefulWidget {
  final Function(LangOptions) languageSelected;
  final String currentLanguage;
  final bool activeFilter;

  LanguageList(
      {required this.languageSelected,
      required this.currentLanguage,
      required this.activeFilter});

  @override
  State<LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<LanguageList> {
  final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Color.fromARGB(219, 11, 185, 216),
      fontSize: 10.0,
      fontWeight: FontWeight.w400,
    ),
  );

  final TextStyle quicksandTextStyleWhite = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 10.0,
      fontWeight: FontWeight.w400,
    ),
  );

  final TextStyle quicksandTextStyle2 = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    ),
  );

  Color baseColor = Color(0xFF202124);

  String selectedLanguage = "-";
  List<String> downloadedLanguages = [];
  String message = ""; // Download Message
  bool isDownloading = false;
  double downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    loadData();
    loadDownloadedLanguages();
  }

  //load downloaded languages
  Future<void> loadDownloadedLanguages() async {
    List<String> downloaded = await getDownloadedLanguages();
    setState(() {
      downloadedLanguages = downloaded;
    });
  }

  // Funktion, um die JSON-Datei zu laden und zu parsen
  Future<List<LangOptions>> loadData() async {
    // Lade die JSON-Datei aus den Assets
    final String response =
        await rootBundle.loadString('assets/languages.json');

    // Die JSON-Daten dekodieren
    final Map<String, dynamic> data =
        json.decode(response); // Hier erwarten wir ein einzelnes Objekt

    // Extrahiere die Liste der Sprachen
    final List<dynamic> languagesData = data[
        'languages']; // 'languages' ist der Schlüssel in deinem JSON-Objekt

    List<LangOptions> languages = languagesData
        .map((e) => LangOptions.fromJson(e as Map<String, dynamic>))
        .toList();

    // Lade heruntergeladene Sprachen
    List<String> downloaded = await getDownloadedLanguages();

    if (widget.activeFilter) {
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);
      final fetchedDocuments = documentProvider.allDocuments;

      List<String> usedLanguages = [];
      for (var doc in fetchedDocuments) {
        usedLanguages.add(doc.language);
      }

      languages = languages
          .where((lang) => usedLanguages.contains(lang.langCode))
          .toList();
    }

    // Sortiere die Liste so, dass heruntergeladene Sprachen oben erscheinen
    languages.sort((a, b) {
      // Überprüfe zuerst, ob a oder b heruntergeladen ist
      if (downloaded.contains(a.langCode) && !downloaded.contains(b.langCode)) {
        return -1; // a kommt zuerst, wenn a heruntergeladen ist, b aber nicht
      }
      if (!downloaded.contains(a.langCode) && downloaded.contains(b.langCode)) {
        return 1; // b kommt zuerst, wenn b heruntergeladen ist, a aber nicht
      }

      // Wenn beide entweder heruntergeladen sind oder nicht, dann alphabetisch sortieren
      return a.language
          .compareTo(b.language); // Alphabetische Sortierung nach Sprachname
    });

    // Rückgabe der geladenen und sortierten Sprachen
    return languages;
  }

// Funktion, um die Sprachdatei herunterzuladen
  Future<void> addLanguage(String langCode, String langName) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    if (isDownloading) {
      // Zeige den Fortschrittsdialog
      showDialog(
        context: context,
        barrierDismissible:
            false, // Verhindere, dass der Benutzer den Dialog schließt
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFF0F1820),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Herunterladen von $langName...',
                    style: quicksandTextStyle2),
                SizedBox(height: 20),
                ProgressIndicatorExample(), // Fortschrittsbalken
              ],
            ),
          );
        },
      );
    }

    try {
      print("in AddLanguage");
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          'https://github.com/tesseract-ocr/tessdata/raw/main/${langCode}.traineddata'));
      HttpClientResponse response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);

      print(request);
      print(response);

      String dir = await FlutterTesseractOcr.getTessdataPath();

      // Verzeichnis erstellen, falls nicht vorhanden
      Directory tessDataDir = Directory(dir);
      if (!await tessDataDir.exists()) {
        print('Creating tessdata directory...');
        await tessDataDir.create(recursive: true);
      }

      File file = File('$dir/$langCode.traineddata');

      // Die heruntergeladene Sprachdatei speichern
      await file.writeAsBytes(bytes);
      isDownloading = false;

      // Bestätigung
      print('$langCode wurde erfolgreich heruntergeladen und gespeichert!');
      // Schließe den Dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Aktualisiere den Zustand
      setState(() {
        downloadedLanguages.add(langCode); // Sprache zur Liste hinzufügen
      });
    } catch (e) {
      print('Fehler beim Hinzufügen der Sprache: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

//Show downloaded Languages
  Future<List<String>> getDownloadedLanguages() async {
    String tessdataPath = await FlutterTesseractOcr.getTessdataPath();
    Directory tessdataDir = Directory(tessdataPath);

    if (!tessdataDir.existsSync()) {
      return [];
    }

    // Liste aller Dateien im Verzeichnis
    List<FileSystemEntity> files = tessdataDir.listSync();

    // Filtern der Dateien, die auf ".traineddata" enden
    return files
        .whereType<File>()
        .where((file) => file.path.endsWith('.traineddata'))
        .map((file) => file.uri.pathSegments.last
            .split('.')
            .first) // Name ohne ".traineddata"
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle quicksandTextStyleLocalName = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return FutureBuilder<List<LangOptions>>(
      // Hier wird die Funktion aufgerufen, die die Daten lädt
      future: loadData(),
      builder: (context, snapshot) {
        // Wenn die Daten geladen werden
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Wenn ein Fehler beim Laden auftritt
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        // Wenn keine Daten vorhanden sind
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Keine Sprachen verfügbar.'));
        }

        // Wenn die Daten erfolgreich geladen wurden, zeige die Liste
        List<LangOptions> languages = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: baseColor, // Hintergrundfarbe des Containers
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white, // Farbe der unteren Grenze
                    width: 0.5, // Dicke der unteren Grenze
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Verfügbare Sprachen', // Der zusätzliche Text über der Liste
                style: GoogleFonts.quicksand(
                  textStyle: TextStyle(
                    color: Color.fromARGB(219, 11, 185, 216),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isDownloaded =
                      downloadedLanguages.contains(lang.langCode);

                  return ListTile(
                    title: Text(lang.language,
                        style:
                            quicksandTextStyle2), // Anzeige des englischen Namens der Sprache
                    subtitle: Text(lang.localName,
                        style:
                            quicksandTextStyleLocalName), // Anzeige des native Namens der Sprache
                    leading: isDownloaded
                        ? Icon(Icons.check,
                            color: Color.fromARGB(219, 11, 185,
                                216)) // Sprache wurde heruntergeladen
                        : IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () async {
                              await addLanguage(lang.langCode,
                                  lang.language); // Sprache herunterladen
                            },
                          ),
                    onTap: isDownloaded
                        ? () {
                            setState(() {
                              widget.languageSelected(
                                  lang); // Callback für übergeordneten Screen
                            });
                            Navigator.pop(context, lang); // Sprache zurückgeben
                          }
                        : null, // Deaktiviert onTap, wenn Sprache nicht heruntergeladen ist
                    tileColor: isDownloaded
                        ? (lang.langCode == widget.currentLanguage
                            ? const Color.fromARGB(219, 15, 219, 255)
                                .withOpacity(
                                    0.1) // Hervorhebung der ausgewählten Sprache
                            : null) // Keine Farbe für heruntergeladene, aber nicht ausgewählte Sprachen
                        : const Color.fromARGB(255, 162, 156, 162).withOpacity(
                            0.1), // Ausgrauen für nicht heruntergeladene Sprachen
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
