import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:scandocus_app/main.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';

import '../models/lang_options.dart';
import '../widgets/language_list.dart';
import 'home_page.dart';

// class OcrPage extends StatefulWidget {
//   const OcrPage({super.key});

//   @override
//   OcrPageState createState() => OcrPageState();
// }

// class OcrPageState extends State<OcrPage> {
//   var showText = "Hier wird Text angezeigt";

//   File? selectedImage; // Ausgewähltes Bild als Datei

//   String selectedLanguage = "eng";

//   // Methode für die OCR-Erkennung
//   Future<void> performOCR() async {
//     if (selectedImage == null) {
//       setState(() {
//         showText = "Bitte wähle zuerst ein Bild aus!";
//       });
//       return;
//     }

//     try {
//       print("OCR wird ausgeführt...");
//       String extractedText = await FlutterTesseractOcr.extractText(
//         selectedImage!.path, // Pfad zum ausgewählten Bild
//         language: selectedLanguage,
//       );

//       // Aktualisiere den Status
//       setState(() {
//         showText = extractedText;
//       });
//     } catch (e) {
//       setState(() {
//         showText = "Fehler bei der OCR-Erkennung: $e";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text("Vorschau"),
//         ),
//         body: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: FutureBuilder<List<LangOptions>>(
//               future: options,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 } else if (snapshot.hasError) {
//                   return Text("Fehler: ${snapshot.error}");
//                 } else if (snapshot.data == null || snapshot.data!.isEmpty) {
//                   return Text("Keine Optionen verfügbar.");
//                 } else {
//                   // Wenn die Daten erfolgreich geladen wurden
//                   List<LangOptions> data = snapshot.data!;

//                   return Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Flexible(
//                             flex: 2,
//                             child: DropdownButton<LangOptions>(
//                               value: selectedOption,
//                               hint: Text('Wähle eine Option'),
//                               isExpanded: true,
//                               onChanged: (LangOptions? newValue) {
//                                 setState(() {
//                                   selectedOption = newValue;
//                                 });

//                                 //set Language in AppState
//                                 if (newValue != null) {
//                                   setLanguage(newValue.code);
//                                 }
//                               },
//                               items: (() {
//                                 List<LangOptions> sortedData = data.toList();
//                                 sortedData.sort((a, b) {
//                                   bool isADownloaded =
//                                       downloadedLanguages.contains(a.code);
//                                   bool isBDownloaded =
//                                       downloadedLanguages.contains(b.code);

//                                   //Manuelles Sortieren: true(heruntergeladen) kommt zuerst
//                                   if (isBDownloaded && !isADownloaded) return 1;
//                                   if (isADownloaded && !isBDownloaded)
//                                     return -1;
//                                   return 0;
//                                 });
//                                 //Convert in DropDownMenuItem
//                                 return sortedData.map((LangOptions option) {
//                                   bool isDownloaded =
//                                       downloadedLanguages.contains(option.code);

//                                   return DropdownMenuItem<LangOptions>(
//                                     value: option,
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(option.englishName),
//                                         if (isDownloaded)
//                                           Icon(Icons.check,
//                                               color: Colors.green),
//                                       ],
//                                     ),
//                                   );
//                                 }).toList();
//                               })(),
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           ElevatedButton(
//                             onPressed: downloadLanguage,
//                             child: Icon(Icons.download),
//                           ),
//                         ],
//                       ),

//                       //Show message after Download
//                       if (message.isNotEmpty)
//                         Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(message)),
//                       ElevatedButton(
//                           onPressed: pickImage,
//                           child: Text("Bild aus Galerie wählen")),
//                       if (selectedImage != null)
//                         Image.file(
//                           selectedImage!,
//                         ),
//                       ElevatedButton(
//                         onPressed: performOCR,
//                         child: Text("OCR ausführen"),
//                       ),
//                       Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             showText,
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class OcrProcessView extends StatefulWidget {
  final List<CameraDescription> cameras;

  final File? selectedImage; // Ausgewähltes Bild als Datei
  final String? takenPicture;

  const OcrProcessView(
      {super.key,
      this.selectedImage,
      required this.cameras,
      this.takenPicture});

  @override
  State<OcrProcessView> createState() => _OcrProcessViewState();
}

class _OcrProcessViewState extends State<OcrProcessView> {
  late File? selectedImage; // Ausgewähltes Bild als Datei
  late String? takenPicture;
  var showText = "Hier wird Text angezeigt";
  String selectedLanguage = "eng";

  @override
  void initState() {
    super.initState();
    selectedImage =
        widget.selectedImage; // Das Bild aus dem Widget-Parameter setzen

    takenPicture = widget.takenPicture;
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

    // Überprüfen, ob `selectedImage` oder `takenPicture` nicht null sind
    if (selectedImage != null) {
      imagePath = selectedImage!
          .path; // Wenn `selectedImage` nicht null ist, verwenden wir diesen Pfad
    } else if (takenPicture != null) {
      imagePath =
          takenPicture!; // Wenn `takenPicture` nicht null ist, verwenden wir diesen Pfad
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
        showText = extractedText;
      });
    } catch (e) {
      setState(() {
        showText = "Fehler bei der OCR-Erkennung: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR-Verarbeitung"), leading: null),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                selectedImage != null && takenPicture == null
                    ? Image.file(
                        selectedImage!) // Das ausgewählte Bild anzeigen
                    : (selectedImage == null && takenPicture != null
                        ? Image.file(File(
                            takenPicture!)) // Das aufgenommene Bild anzeigen
                        : Text("Kein Bild ausgewählt!")),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      showText,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(cameras: widget.cameras),
                      ),
                    );
                    print("Speichernbutton gedrückt");
                  },
                  icon: const Icon(Icons.save),
                  label: Text("Speichern"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
