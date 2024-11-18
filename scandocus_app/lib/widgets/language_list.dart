import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/lang_options.dart';

class LanguageList extends StatefulWidget {
  final Function(LangOptions) languageSelected;
  final String currentLanguage; // Aktuell ausgewählte Sprache

  LanguageList({required this.languageSelected, required this.currentLanguage});

  @override
  State<LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<LanguageList> {
  String selectedLanguage = "eng";
  List<String> downloadedLanguages = [];
  String message = ""; // Download Message

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

    // Sortiere die Liste so, dass heruntergeladene Sprachen oben erscheinen
    languages.sort((a, b) {
      if (downloaded.contains(a.code)) return -1; // a kommt zuerst
      if (downloaded.contains(b.code)) return 1; // b kommt zuerst
      return 0; // Keine Änderung
    });

    // Rückgabe der geladenen und sortierten Sprachen
    return languages;
  }

// Funktion, um die Sprachdatei herunterzuladen
  Future<void> addLanguage(String langCode) async {
    try {
      print("in AddLanguage");
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          'https://github.com/tesseract-ocr/tessdata/raw/main/${langCode}.traineddata'));
      HttpClientResponse response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);

      String dir = await FlutterTesseractOcr.getTessdataPath();
      File file = File('$dir/$langCode.traineddata');

      // Die heruntergeladene Sprachdatei speichern
      await file.writeAsBytes(bytes);

      // Bestätigung
      print('$langCode wurde erfolgreich heruntergeladen und gespeichert!');
      // Aktualisiere den Zustand
      setState(() {
        downloadedLanguages.add(langCode); // Sprache zur Liste hinzufügen
      });
    } catch (e) {
      print('Fehler beim Hinzufügen der Sprache: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprachoptionen'),
      ),
      body: FutureBuilder<List<LangOptions>>(
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

          return ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isDownloaded = downloadedLanguages.contains(lang.code);

              return ListTile(
                title: Text(lang
                    .englishName), // Anzeige des englischen Namens der Sprache
                subtitle: Text(
                    lang.nativeName), // Anzeige des native Namens der Sprache
                leading: isDownloaded
                    ? Icon(Icons.check,
                        color: Colors.green) // Sprache wurde heruntergeladen
                    : IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () async {
                          await addLanguage(lang.code); // Sprache herunterladen
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
                    ? (lang.code == widget.currentLanguage
                        ? const Color.fromARGB(255, 116, 8, 132).withOpacity(
                            0.1) // Hervorhebung der ausgewählten Sprache
                        : null) // Keine Farbe für heruntergeladene, aber nicht ausgewählte Sprachen
                    : const Color.fromARGB(255, 61, 59, 61).withOpacity(
                        0.1), // Ausgrauen für nicht heruntergeladene Sprachen
              );
            },
          );
        },
      ),
    );
  }
}
