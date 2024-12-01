import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/doc_page_overview.dart';
import 'dart:io';

import '../utils/document_provider.dart';
import '../widgets/language_list.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';

class OcrProcessView extends StatefulWidget {
  // final List<CameraDescription> cameras;

  final File? selectedImage; // Ausgewähltes Bild als Datei
  final String? takenPicture;
  final String? existingImage;
  final String? existingFilename;
  final String? existingId;
  final int? existingPage;
  final bool? replaceImage;

  const OcrProcessView(
      {super.key,
      this.selectedImage,
      // required this.cameras,
      this.takenPicture,
      this.existingImage,
      this.existingFilename,
      this.existingId,
      this.existingPage,
      this.replaceImage});

  @override
  State<OcrProcessView> createState() => _OcrProcessViewState();
}

class _OcrProcessViewState extends State<OcrProcessView> {
  late File? selectedImage; // Ausgewähltes Bild als Datei
  late String? takenPicture;
  late String? existingFilename;
  late String? existingImage;
  late String? existingId;
  late int? existingPage;
  late bool? replaceImage;
  var showText = "Hier wird Text angezeigt";
  String selectedLanguage = "eng";

  bool isDownloading = false;
  bool isScanning = false;
  bool scanningDone = false;

  @override
  void initState() {
    super.initState();
    selectedImage =
        widget.selectedImage; // Das Bild aus dem Widget-Parameter setzen

    takenPicture = widget.takenPicture;
    existingImage = widget.existingImage;
    existingId = widget.existingId;
    existingPage = widget.existingPage;
    existingFilename = widget.existingFilename;
    replaceImage = widget.replaceImage;
  }

  Future<void> updateDocument(String image, String id, String filename,
      String text, String language, int page) async {
    final apiService = ApiService();
    final now = DateTime.now();
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    final String imagePath;
    if (takenPicture != null) {
      imagePath = await apiService.uploadImage(File(image));
    } else {
      imagePath = image;
    }

    await apiService.sendDataToServer(
      filename,
      text,
      language: language,
      scanDate: formatter.format(now),
      imageUrl: imagePath,
      id: id,
      pageNumber: page,
    );
    print("Dokument gespeichert!");

    print('Daten erfolgreich an Solr gesendet.');
    // Dokumentliste aktualisieren
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);
    await documentProvider.fetchDocuments();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) =>
              DocumentPageOvereview(fileName: existingFilename!)),
      (route) => route.isFirst, // Behält nur die erste Seite im Stack
    );
    print("Speichern Button gedrückt");
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LanguageList(
              currentLanguage: selectedLanguage,
              languageSelected: (newLang) {
                setState(() {
                  selectedLanguage = newLang.code;
                });
              }),
        );
      },
    );
  }

  // Methode für die OCR-Erkennung
  Future<void> performOCR() async {
    String? imagePath;
    setState(() {
      isScanning = true; //activate
      scanningDone = false;
    });

    // Überprüfen, ob `selectedImage` oder `takenPicture` nicht null sind
    if (selectedImage != null) {
      imagePath = selectedImage!
          .path; // Wenn `selectedImage` nicht null ist, verwenden wir diesen Pfad
    } else if (takenPicture != null) {
      imagePath =
          takenPicture!; // Wenn `takenPicture` nicht null ist, verwenden wir diesen Pfad
    } else if (existingImage != null) {
      imagePath =
          await downloadImage('http://192.168.178.193:3000${existingImage!}');
    } else {
      print("Kein Bild zum Extrahieren vorhanden!");
      setState(() {
        showText = "Kein Bild zum Extrahieren vorhanden!";
      });
      return; // Beenden, wenn kein Bild vorhanden ist
    }

    try {
      print("OCR wird ausgeführt...");

      String extractedText = await FlutterTesseractOcr.extractText(
        imagePath, // Pfad zum ausgewählten Bild
        language: selectedLanguage,
      );

      // Aktualisiere den Status
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = extractedText;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = "Fehler bei der OCR-Erkennung: $e";
      });
    }
  }

  //Existierendes Bild herunterladen für Tesserect ansonsten kann es nicht nochmal gescannt werden
  Future<String> downloadImage(String url) async {
    try {
      // Lade das Bild herunter
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Speichere die Datei im temporären Verzeichnis
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/downloaded_image.jpg';
        final file = File(filePath);

        // Schreibe die Bilddaten in die Datei
        await file.writeAsBytes(response.bodyBytes);

        return file.path; // Gibt den lokalen Pfad zurück
      } else {
        throw Exception(
            'Fehler beim Herunterladen des Bildes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Herunterladen des Bildes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    bool imageExists = false;
    bool idExists = false;
    int? samePage;

    // Bedingungen prüfen und Variablen setzen
    if (existingImage != null && existingImage!.isNotEmpty) {
      imageUrl = 'http://192.168.178.193:3000${existingImage!}'; // Bild-URL
      imageExists = true;
    }

    if (replaceImage != null) {
      idExists = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text("OCR-Verarbeitung"), leading: null),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                if (selectedImage != null &&
                    takenPicture == null &&
                    existingImage == null)
                  // Lokale Datei anzeigen, wenn ein ausgewähltes Bild vorhanden ist
                  Image.file(selectedImage!)
                else if (takenPicture != null &&
                    selectedImage == null &&
                    existingImage == null)
                  // Lokale Datei von der aufgenommenen Bild-URL anzeigen
                  Image.file(File(takenPicture!))
                else if (existingImage != null &&
                    takenPicture == null &&
                    selectedImage == null)

                  // Falls weder ein Bild noch ein Pfad angegeben ist, versuche, das Bild über eine URL anzuzeigen
                  Image.network(
                    imageUrl!,
                    errorBuilder: (context, error, stackTrace) {
                      // Fehlerbehandlung: Zeige ein Icon, wenn das Bild nicht geladen werden kann
                      return const Icon(Icons.error);
                    },
                  )
                else
                  // Wenn keine Bedingung zutrifft, zeige ein Icon für nicht unterstützte Inhalte
                  const Icon(Icons.image_not_supported),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          print("Sprachbutton gedrückt");
                          _showLanguageDialog(context);
                        },
                        icon: const Icon(Icons.language),
                        label: Text(selectedLanguage),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: performOCR,
                        child: Text("Text scannen"),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: isScanning,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text('Text wird erkannt...'),
                          SizedBox(height: 10),
                          ProgressIndicatorExample(),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: scanningDone,
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            showText, // Text anzeigen
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      imageExists
                          ? ElevatedButton.icon(
                              onPressed: () {
                                updateDocument(
                                    existingImage!,
                                    existingId!,
                                    existingFilename!,
                                    showText,
                                    selectedLanguage,
                                    existingPage!);
                              },
                              icon: const Icon(Icons.save),
                              label: Text("Speichern"),
                            )
                          : idExists
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    updateDocument(
                                        takenPicture!,
                                        existingId!,
                                        existingFilename!,
                                        showText,
                                        selectedLanguage,
                                        existingPage!);
                                  },
                                  icon: const Icon(Icons.save),
                                  label: Text("Speichern"),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context, {
                                      'scannedText': showText,
                                      'selectedLanguage': selectedLanguage,
                                    }); // Text zurückgeben
                                    print("Verwenden Button gedrückt");
                                  },
                                  icon: const Icon(Icons.check),
                                  label: Text("Verwenden"),
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
