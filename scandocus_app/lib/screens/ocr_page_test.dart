// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
// import 'dart:io';

// import '../widgets/language_list.dart';
// import '../widgets/progress_bar.dart';
// import '../services/api_service.dart';
// import '../models/document_session.dart';

// class OcrProcessView extends StatefulWidget {
//   // final List<CameraDescription> cameras;

//   final File? selectedImage; // Ausgewähltes Bild als Datei
//   final String? takenPicture;
//   final DocumentSession? session;

//   const OcrProcessView(
//       {super.key,
//       this.selectedImage,
//       // required this.cameras,
//       this.takenPicture,
//       this.session});

//   @override
//   State<OcrProcessView> createState() => _OcrProcessViewState();
// }

// class _OcrProcessViewState extends State<OcrProcessView> {
//   late DocumentSession session;
//   late File? selectedImage; // Ausgewähltes Bild als Datei
//   late String? takenPicture;
//   var showText = "Hier wird Text angezeigt";
//   String selectedLanguage = "eng";

//   bool isDownloading = false;
//   bool isScanning = false;
//   bool scanningDone = false;

//   @override
//   void initState() {
//     super.initState();
//     selectedImage =
//         widget.selectedImage; // Das Bild aus dem Widget-Parameter setzen

//     takenPicture = widget.takenPicture;

//     //Falls keine Session übergeben wird,erstelle eine neue
//     session = widget.session ?? DocumentSession(fileName: "Neues Dokument");
//   }

//   void _showLanguageDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: LanguageList(
//               currentLanguage: selectedLanguage,
//               languageSelected: (newLang) {
//                 setState(() {
//                   selectedLanguage = newLang.code;
//                 });
//               }),
//         );
//       },
//     );
//   }

//   // Methode für die OCR-Erkennung
//   Future<void> performOCR() async {
//     String? imagePath = selectedImage?.path ?? takenPicture;

//     setState(() {
//       isScanning = true; //activate
//       scanningDone = false;
//     });

//     if (imagePath == null) {
//       setState(() {
//         showText = "Kein Bild zum Extrahieren vorhanden!";
//       });
//       return;
//     }

//     try {
//       print("OCR wird ausgeführt...");

//       String extractedText = await FlutterTesseractOcr.extractText(
//         imagePath, // Pfad zum ausgewählten Bild
//         language: selectedLanguage,
//       );

//       // Aktualisiere den Status
//       setState(() {
//         isScanning = false;
//         scanningDone = true;
//         showText = extractedText;

//         //Aktuelle Seite zur Session hinzufügen
//         session.addPage(DocumentPage(
//           imagePath: imagePath,
//           scannedText: extractedText,
//           captureDate: "2024-11-24T10:00:00Z",
//           pageNumber: session.pages.length + 1,
//         ));
//       });
//     } catch (e) {
//       setState(() {
//         isScanning = false;
//         scanningDone = true;
//         showText = "Fehler bei der OCR-Erkennung: $e";
//       });
//     }
//   }

//   Future<void> saveImageAndSendData() async {
//     // Stelle sicher, dass ein Bild vorhanden ist
//     if (selectedImage == null && takenPicture == null) {
//       print('Kein Bild zum Speichern und Senden vorhanden.');
//       return;
//     }

//     try {
//       // Bildquelle bestimmen (Galerie oder Kamera)
//       final File imageFile = selectedImage ?? File(takenPicture!);

//       // Bild lokal speichern
//       final directory =
//           await getApplicationDocumentsDirectory(); //Pfad vom Anwenderverzeichnis holen
//       // Erstelle den Ordnerpfad
//       final folderPath = '${directory.path}/Scan2Doc';

//       // Überprüfe, ob der Ordner existiert, und erstelle ihn, falls nicht
//       final folder = Directory(folderPath);
//       if (!await folder.exists()) {
//         await folder.create(recursive: true); // Ordner erstellen
//         print('Ordner erstellt: $folderPath');
//       } else {
//         print('Ordner existiert bereits: $folderPath');
//       }

//       final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final filePath = '$folderPath/$fileName';
//       await imageFile.copy(filePath);

//       print('Bild erfolgreich gespeichert: $filePath');

//       // Textdaten und Bild-URL an Solr senden
//       final apiService = ApiService(); // Dein API-Service
//       for (var page in session.pages) {
//         await apiService.sendDataToServer(
//           session.fileName, // Beispiel Dateiname
//           page.scannedText, // Erkannter Text aus OCR
//           language: selectedLanguage,
//           scanDate: page.captureDate, //"2024-11-24T10:00:00Z",
//           imageUrl: page.imagePath, // Lokaler Pfad des Bildes
//         );
//       }

//       print('Daten erfolgreich an Solr gesendet.');
//     } catch (e) {
//       print('Fehler beim Speichern und Senden: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(session.fileName), leading: null),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Center(
//             child: Column(
//               children: [
//                 selectedImage != null && takenPicture == null
//                     ? Image.file(
//                         selectedImage!) // Das ausgewählte Bild anzeigen
//                     : (selectedImage == null && takenPicture != null
//                         ? Image.file(File(
//                             takenPicture!)) // Das aufgenommene Bild anzeigen
//                         : Text("Kein Bild ausgewählt!")),
//                 Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           print("Sprachbutton gedrückt");
//                           _showLanguageDialog(context);
//                         },
//                         icon: const Icon(Icons.language),
//                         label: Text(selectedLanguage),
//                       ),
//                       SizedBox(width: 20),
//                       ElevatedButton(
//                         onPressed: performOCR,
//                         child: Text("Text scannen"),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Visibility(
//                   visible: isScanning,
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(10.0),
//                       child: Column(
//                         children: [
//                           Text('Text wird erkannt...'),
//                           SizedBox(height: 10),
//                           ProgressIndicatorExample(),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Visibility(
//                   visible: scanningDone,
//                   child: Column(
//                     children: [
//                       Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             showText, // Text anzeigen
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () async {
//                           // Navigator.pushReplacement(
//                           //   context,
//                           //   MaterialPageRoute(
//                           //     builder: (context) => HomePage(cameras: widget.cameras),
//                           //   ),
//                           // );
//                           // Dynamische Prüfungen und Fallback-Logik
//                           // await apiService.testConnection();
//                           saveImageAndSendData();
//                           print("Speichernbutton gedrückt");
//                         },
//                         icon: const Icon(Icons.save),
//                         label: Text("Speichern"),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.pop(context); // Zurück zur Kamera
//                           print("weitere seite");
//                         },
//                         icon: const Icon(Icons.plus_one),
//                         label: Text("Speichern"),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
