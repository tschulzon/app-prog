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

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

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
          backgroundColor: Color(0xFF202124),
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

    Widget customImageWidget() {
      if (selectedImage != null &&
          takenPicture == null &&
          existingImage == null) {
        return Image.file(selectedImage!);
      } else if (takenPicture != null &&
          selectedImage == null &&
          existingImage == null) {
        return Image.file(takenPicture! as File);
      } else if (existingImage != null &&
          takenPicture == null &&
          selectedImage == null) {
        return Image.network(
          imageUrl!,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error);
          },
        );
      } else {
        return const Icon(Icons.image_not_supported);
      }
    }

    Color baseColor = Color(0xFF202124);
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleButton = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: baseColor,
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
      ),
    );

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("OCR-Verarbeitung"),
        titleTextStyle: GoogleFonts.quicksand(
          textStyle: TextStyle(
            color: Color.fromARGB(219, 11, 185, 216),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: baseColor,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(219, 11, 185, 216), // Farbe des Zurück-Pfeils
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClayContainer(
                  depth: 13,
                  spread: 5,
                  borderRadius: 20,
                  color: baseColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: customImageWidget()),
                  ),
                ),
                // child: if (selectedImage != null &&
                //     takenPicture == null &&
                //     existingImage == null)
                //   // Lokale Datei anzeigen, wenn ein ausgewähltes Bild vorhanden ist
                //   Image.file(selectedImage!)
                // else if (takenPicture != null &&
                //     selectedImage == null &&
                //     existingImage == null)
                //   // Lokale Datei von der aufgenommenen Bild-URL anzeigen
                //   Image.file(File(takenPicture!))
                // else if (existingImage != null &&
                //     takenPicture == null &&
                //     selectedImage == null)

                //   // Falls weder ein Bild noch ein Pfad angegeben ist, versuche, das Bild über eine URL anzuzeigen
                //   Image.network(
                //     imageUrl!,
                //     errorBuilder: (context, error, stackTrace) {
                //       // Fehlerbehandlung: Zeige ein Icon, wenn das Bild nicht geladen werden kann
                //       return const Icon(Icons.error);
                //     },
                //   )
                // else
                //   // Wenn keine Bedingung zutrifft, zeige ein Icon für nicht unterstützte Inhalte
                //   const Icon(Icons.image_not_supported),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClayContainer(
                      spread: 3,
                      surfaceColor: Color.fromARGB(219, 11, 185, 216),
                      color: baseColor,
                      borderRadius: 30,
                      child: GestureDetector(
                        onTap: () {
                          print("Sprachbutton gedrückt");
                          _showLanguageDialog(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.language,
                                  color: Color(0xFF202124)),
                              const SizedBox(width: 5.0),
                              Text(selectedLanguage,
                                  style: quicksandTextStyleButton),
                            ],
                          ),
                        ),
                        // icon: const Icon(Icons.language),
                        // label: Text(selectedLanguage),
                      ),
                    ),
                    SizedBox(width: 20),
                    ClayContainer(
                      spread: 3,
                      surfaceColor: Color.fromARGB(219, 11, 185, 216),
                      color: baseColor,
                      borderRadius: 30,
                      child: GestureDetector(
                        onTap: performOCR,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text("Text scannen",
                              style: quicksandTextStyleButton),
                        ),
                      ),
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
                        Text('Text wird erkannt...', style: quicksandTextStyle),
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClayContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                showText, // Text anzeigen
                                textAlign: TextAlign.center,
                                style: quicksandTextStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    imageExists
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClayContainer(
                              spread: 3,
                              surfaceColor: Color.fromARGB(219, 11, 185, 216),
                              width: 220,
                              color: baseColor,
                              borderRadius: 30,
                              child: GestureDetector(
                                onTap: () {
                                  updateDocument(
                                      existingImage!,
                                      existingId!,
                                      existingFilename!,
                                      showText,
                                      selectedLanguage,
                                      existingPage!);
                                },
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.save,
                                            color: Color(0xFF202124)),
                                        const SizedBox(width: 5.0),
                                        Text("Speichern",
                                            style: quicksandTextStyleButton)
                                      ],
                                    )),
                              ),
                            ),
                          )
                        : idExists
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClayContainer(
                                  spread: 3,
                                  surfaceColor:
                                      Color.fromARGB(219, 11, 185, 216),
                                  width: 220,
                                  color: baseColor,
                                  borderRadius: 30,
                                  child: GestureDetector(
                                    onTap: () {
                                      updateDocument(
                                          takenPicture!,
                                          existingId!,
                                          existingFilename!,
                                          showText,
                                          selectedLanguage,
                                          existingPage!);
                                    },
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.save,
                                                color: Color(0xFF202124)),
                                            const SizedBox(width: 5.0),
                                            Text("Speichern",
                                                style: quicksandTextStyleButton)
                                          ],
                                        )),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ClayContainer(
                                  spread: 5,
                                  surfaceColor:
                                      Color.fromARGB(219, 11, 185, 216),
                                  width: 220,
                                  color: baseColor,
                                  borderRadius: 30,
                                  child: GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context, {
                                        'scannedText': showText,
                                        'selectedLanguage': selectedLanguage,
                                      }); // Text zurückgeben
                                      print("Verwenden Button gedrückt");
                                    },
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check,
                                                color: Color(0xFF202124)),
                                            const SizedBox(width: 5.0),
                                            Text("Verwenden",
                                                style: quicksandTextStyleButton)
                                          ],
                                        )),
                                  ),
                                ),
                              )
                    // ? ElevatedButton.icon(
                    //     onPressed: () {
                    //       updateDocument(
                    //           takenPicture!,
                    //           existingId!,
                    //           existingFilename!,
                    //           showText,
                    //           selectedLanguage,
                    //           existingPage!);
                    //     },
                    //     icon: const Icon(Icons.save),
                    //     label: Text("Speichern"),
                    //   )
                    // : ElevatedButton.icon(
                    //     onPressed: () async {
                    //       Navigator.pop(context, {
                    //         'scannedText': showText,
                    //         'selectedLanguage': selectedLanguage,
                    //       }); // Text zurückgeben
                    //       print("Verwenden Button gedrückt");
                    //     },
                    //     icon: const Icon(Icons.check),
                    //     label: Text("Verwenden"),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
