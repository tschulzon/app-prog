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

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  TimeOfDay selectedTime = TimeOfDay.now(); // Aktuelle Zeit initialisieren
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Hier verwenden wir StatefulBuilder damit die Zeit nach dem TimePicker automatisch aktualisiert wird
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Dialog(
              insetAnimationCurve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                height: 600,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Filter-Optionen",
                            style: TextStyle(fontSize: 16)),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text("Scan-Datum: "),
                            const SizedBox(height: 10),
                            InputDatePickerFormField(
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              initialDate: DateTime.now(),
                              onDateSubmitted: (date) {
                                // Hier kannst du den Filter anwenden, wenn ein Datum ausgewählt wurde
                                print("Datum ausgewählt: $date");
                              },
                              onDateSaved: (date) {
                                print("Datum gespeichert: $date");
                              },
                            ),
                            Divider(),
                            SizedBox(height: 20),
                            // Zeigt die aktuell ausgewählte Zeit an
                            Text('Scan-Uhrzeit: '),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(selectedTime.format(context)),
                                ElevatedButton(
                                    onPressed: () async {
                                      // Öffne den TimePicker
                                      final TimeOfDay? pickedTime =
                                          await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime,
                                      );

                                      if (pickedTime != null &&
                                          pickedTime != selectedTime) {
                                        // Die Zeit sofort im Dialog aktualisieren
                                        setStateDialog(() {
                                          selectedTime = pickedTime;
                                        });
                                      }
                                    },
                                    child: Icon(Icons.schedule)),
                              ],
                            ),
                            Divider(),
                            Text("Seitenzahl: "),
                            TextField(keyboardType: TextInputType.number),
                            Divider(),
                            Text("Sprache: ")
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Hier kannst du die Logik für den Filter anwenden
                          // Der Dialog bleibt geöffnet, da wir den Dialog nicht schließen
                        },
                        child: const Text("Anwenden"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    onChanged: (String value) {
                      print("Suchabfrage: $value");
                    },
                    leading: const Icon(Icons.search),
                    hintText: "Dateiname suchen",
                    trailing: <Widget>[
                      IconButton(
                        onPressed: () {
                          print("Button wurde gedrückt");
                          _showFilterDialog(context);
                        },
                        icon: const Icon(Icons.filter_alt),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const Card(
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 70,
                        height: 100,
                        child: Placeholder(),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dateiname"),
                          SizedBox(
                            height: 30,
                          ),
                          Text("Datum und Uhrzeit lol")
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
            const Divider(),
            const Card(
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 70,
                        height: 100,
                        child: Placeholder(),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dateiname"),
                          SizedBox(
                            height: 30,
                          ),
                          Text("Datum und Uhrzeit lol")
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
