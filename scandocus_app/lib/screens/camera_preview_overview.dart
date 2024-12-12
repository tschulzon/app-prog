import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scandocus_app/main.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'package:scandocus_app/screens/ocr_page.dart';
import 'dart:io';

import '../models/document.dart';
import '../screens/camera_page.dart';
import '../models/document_session.dart';
import '../screens/ocr_page.dart';
import '../services/api_service.dart';
import '../screens/home_page.dart';

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentOverview extends StatefulWidget {
  final DocumentSession session;
  final String? existingFilename;
  final int? newPage;

  const DocumentOverview(
      {super.key, required this.session, this.existingFilename, this.newPage});

  @override
  State<DocumentOverview> createState() => _DocumentOverviewState();
}

class _DocumentOverviewState extends State<DocumentOverview> {
  late TextEditingController _fileNameController;
  late String? existingFilename;
  late int? newPage;

  @override
  void initState() {
    super.initState();
    // Initialisiere den Controller mit dem Standardnamen
    // _fileNameController = TextEditingController(text: widget.session.fileName);
    // Initialisiere den Controller mit dem Dokumentnamen.
    if (widget.existingFilename != null) {
      _fileNameController =
          TextEditingController(text: widget.existingFilename);
    } else {
      _fileNameController =
          TextEditingController(text: widget.session.fileName);
    }
    existingFilename = widget.existingFilename;
    newPage = widget.newPage;
  }

  @override
  void dispose() {
    // Entferne den Controller, um Speicherlecks zu vermeiden
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> sendDataToSolr() async {
    try {
      print("Session Data");
      print(widget.session);
      // Textdaten und Bild-URL an Solr senden
      final apiService = ApiService();
      for (var page in widget.session.pages) {
        // Bild hochladen und Pfad erhalten
        final imagePath = await apiService.uploadImage(File(page.imagePath));
        String currentFilename = existingFilename ?? widget.session.fileName;
        int currentPage = newPage ?? page.pageNumber;
        String documentTime = getTimeOfDate(page.captureDate);

        await apiService.sendDataToServer(
          currentFilename,
          page.scannedText, // Text aus OCR
          language: page.language,
          scanDate: page.captureDate,
          scanTime: documentTime,
          imageUrl: imagePath,
          pageNumber: currentPage,
        );
      }
      print("Dokument gespeichert!");

      print('Daten erfolgreich an Solr gesendet.');
    } catch (e) {
      print('Fehler beim Speichern und Senden: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MyApp()), // Wieder zu MyApp, das AppBar und NavigationBar enthält
        (Route<dynamic> route) => false, // Entfernt alle anderen Routen
      );
    }
  }

  String getTimeOfDate(String date) {
    // Konvertiere den ISO-String in ein DateTime-Objekt
    DateTime dateTime = DateTime.parse(date);

    // Extrahiere die Uhrzeit und formatiere sie als String im gewünschten Format
    String formattedTime =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    // Gib den formatierten Zeitstring aus
    print(formattedTime); // Ausgabe z.b.: "17:15"

    return formattedTime;
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

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
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
        title: Text("Dokumentübersicht"),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClayContainer(
              color: baseColor,
              depth: 13,
              spread: 4,
              borderRadius: 20,
              child: TextField(
                style: quicksandTextStyleTitle,
                controller: _fileNameController,
                decoration: InputDecoration(
                  labelText: "Dokumentname",
                  prefixIcon: Icon(Icons.edit,
                      color: existingFilename != null
                          ? Color.fromARGB(255, 50, 51, 54)
                          : Color.fromARGB(219, 11, 185, 216)),
                  labelStyle: quicksandTextStyle,
                ),
                enabled: existingFilename == null,
                onChanged: (value) {
                  if (existingFilename == null) {
                    // Aktualisiere den Dokumentnamen, wenn der Benutzer etwas eingibt
                    setState(() {
                      widget.session.fileName = _fileNameController.text;
                    });
                    print("NEUER NAME?");
                    print(widget.session.fileName);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Spalten
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    mainAxisExtent: 200,
                  ),
                  itemCount: widget.session.pages.length,
                  itemBuilder: (context, index) {
                    final page = widget.session.pages[index];

                    return GestureDetector(
                      onTap: () async {
                        // Navigiere zur OCR-Seite und aktualisiere den Text
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OcrProcessView(
                              selectedImage: File(page.imagePath),
                            ),
                          ),
                        );

                        if (result != null && result is Map) {
                          page.scannedText = result['scannedText'] ?? "";
                          page.language = result['selectedLanguage'] ?? "eng";
                        }
                      },
                      child: ClayAnimatedContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        borderRadius: 20,
                        curveType: CurveType.none,
                        child: Column(
                          children: [
                            Container(
                              width: 200,
                              height: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12.0),
                                      topRight: Radius.circular(12.0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    )
                                  ]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0)),
                                child: Image.file(
                                  File(page.imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Seite ${index + 1}",
                                  style: quicksandTextStyleTitle),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     sendDataToSolr();
          //     // Zurück zur Startseite
          //     Navigator.popUntil(context, (route) => route.isFirst);
          //     // Speichern und API-Aufruf
          //     // final apiService = ApiService();
          //     // for (var page in session.pages) {
          //     //   await apiService.sendDataToServer(
          //     //     session.fileName,
          //     //     "", // Text wird in einer späteren OCR verarbeitet
          //     //     language: "eng",
          //     //     scanDate: page.captureDate.toIso8601String(),
          //     //     imageUrl: page.imagePath,
          //     //   );
          //     // }
          //     // print("Dokument gespeichert!");

          //     // Zurück zur Startseite
          //     // Navigator.popUntil(context, (route) => route.isFirst);
          //   },
          //   icon: Icon(Icons.save),
          //   label: Text("Dokument speichern"),
          // ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ClayContainer(
          depth: 13,
          spread: 5,
          surfaceColor: Color.fromARGB(219, 11, 185, 216),
          width: 200,
          color: baseColor,
          borderRadius: 30,
          child: GestureDetector(
            onTap: () async {
              await sendDataToSolr();
            },
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, color: Color(0xFF202124)),
                    const SizedBox(width: 5.0),
                    Text("Dokument speichern", style: quicksandTextStyleButton)
                  ],
                )),
          ),
        ),
      ),
      // Padding(
      //   padding: const EdgeInsets.all(50.0),
      //   child: ElevatedButton.icon(
      //     onPressed: () async {
      //       await sendDataToSolr();
      //     },
      //     icon: Icon(Icons.save),
      //     label: Text("Dokument speichern"),
      //   ),
      // ),
    );
  }
}
