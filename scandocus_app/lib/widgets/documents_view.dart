import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:scandocus_app/models/document.dart';
import '../screens/doc_page_overview.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  Future<List<Document>> loadDocuments() async {
    try {
      // Lade die JSON-Datei aus den Assets
      final String response = await rootBundle.loadString('assets/dummy.json');

      // Überprüfe den Inhalt der geladenen JSON-Datei
      print("Geladene JSON-Datei: $response");

      // Parsen des JSON-Strings
      final Map<String, dynamic> data = json.decode(response);

      // Überprüfen, ob 'documents' null ist oder nicht
      if (data['documents'] == null) {
        print('Fehler: "documents" sind null.');
        return []; // Rückgabe einer leeren Liste, wenn keine Dokumente vorhanden sind
      }

      final List<dynamic> documentsList = data['documents'];

      // Umwandlung der JSON-Daten in eine Liste von Document-Objekten
      return documentsList.map((item) => Document.fromJson(item)).toList();
    } catch (e) {
      print("Fehler beim Laden der JSON-Daten: $e");
      return []; // Rückgabe einer leeren Liste im Fehlerfall
    }
  }

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
    return FutureBuilder<List<Document>>(
      future: loadDocuments(),
      builder: (context, snapshot) {
        // Wenn die Daten noch geladen werden
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Wenn ein Fehler auftritt
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        // Wenn keine Daten vorhanden sind
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Keine Dokumente verfügbar.'));
        }

        // Wenn die Daten erfolgreich geladen wurden, zeige die Liste
        List<Document> documents = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Die Suchleiste
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
                              _showFilterDialog(context);
                              // Hier könntest du den Filterdialog anzeigen
                            },
                            icon: const Icon(Icons.filter_alt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Liste der Dokumente aus JSON
              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    Document doc = documents[index];
                    DocumentPage firstPage = doc.pages[0];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DocumentPageOvereview(document: doc)));
                      },
                      child: Card(
                        elevation: 4.0,
                        child: SizedBox(
                          height: 150,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 70,
                                  height: 100,
                                  child: firstPage.image.isNotEmpty
                                      ? Image.asset(
                                          firstPage.image, // Der Pfad zum Bild
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                            return const Icon(Icons.error);
                                          },
                                        )
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.fileName,
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Scan-Datum: ${firstPage.scanDate}'),
                                      Text(
                                          'Scan-Uhrzeit: ${firstPage.scanTime}'),
                                      Text('Sprache: ${firstPage.language}'),
                                      Text('Seitenzahl: ${doc.pages.length}'),
                                      // const SizedBox(height: 8.0),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
