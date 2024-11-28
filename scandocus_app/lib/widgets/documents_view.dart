import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:scandocus_app/models/document.dart';
import '../screens/doc_page_overview.dart';
import '../services/api_service.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  List<Document> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDocuments(); // Initialer Dokumenten-Load
  }

  Future<void> loadDocuments() async {
    try {
      final fetchedDocuments = await ApiService().getSolrData();
      setState(() {
        documents = fetchedDocuments;
        isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Dokumente: $e");
    }
    print("DOKUMENTE:");
    print(documents);
  }

  Future<void> navigateToOverview(
      BuildContext context, List<Document> documents, String fileName) async {
    final updatedDocuments = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPageOvereview(
          documents: documents,
          fileName: fileName,
        ),
      ),
    );

    // Falls die Übersicht aktualisierte Daten zurückgibt, lade neu
    if (updatedDocuments != null) {
      setState(() {
        documents = updatedDocuments;
      });
    } else {
      loadDocuments(); // Alternativ: Komplettes Neuladen
    }
  }

  String formatScanDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String formatScanTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('HH:mm').format(dateTime);
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
    final apiService = ApiService();
    // Gruppiere Dokumente nach `fileName` und zähle die Seiten
    final groupedDocuments = <String, List<Document>>{};
    for (var doc in documents) {
      if (!groupedDocuments.containsKey(doc.fileName)) {
        groupedDocuments[doc.fileName] = [];
      }
      groupedDocuments[doc.fileName]!.add(doc);
    }

    // Erstelle eine Liste aus den gruppierten Dokumenten
    final uniqueDocuments = groupedDocuments.entries
        .map((entry) => {
              "fileName": entry.key,
              "count": entry.value.length,
              "exampleDoc":
                  entry.value.first, // Ein Beispiel-Dokument für Details
            })
        .toList();

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
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: uniqueDocuments.length,
                    itemBuilder: (context, index) {
                      final docInfo = uniqueDocuments[index];
                      final fileName = docInfo["fileName"] as String;
                      final pageCount = docInfo["count"] as int;
                      final exampleDoc = docInfo["exampleDoc"] as Document;
                      final relatedDocs = groupedDocuments[
                          fileName]!; // Liste der zugehörigen Dokumente
                      // final String imageUrl =
                      //     'http://192.168.178.193:3000${exampleDoc.image}'; // Bild-URL
                      final String imageUrl =
                          'http://192.168.2.171:3000${exampleDoc.image}';

                      return Dismissible(
                        key: Key(exampleDoc.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final bool confirm = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Löschen bestätigen"),
                                content: const Text(
                                    "Möchten Sie dieses Dokument wirklich löschen? Dies kann nicht rückgängig gemacht werden."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(false); // Abbrechen
                                    },
                                    child: const Text('Abbrechen'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(true); // Abbrechen
                                    },
                                    child: const Text('Löschen',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm) {
                            // Dokument löschen, wenn bestätigt
                            apiService
                                .deleteManyDocsFromSolr(exampleDoc.fileName);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('$fileName wurde gelöscht')),
                            );
                          }

                          return confirm; // Löschen nur, wenn bestätigt
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 32),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            navigateToOverview(context, relatedDocs, fileName);
                            // Navigiere zur DocumentOverviewPage und übergebe die Dokumente
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => DocumentPageOvereview(
                            //       documents: relatedDocs,
                            //       fileName: fileName,
                            //     ),
                            //   ),
                            // );
                          },
                          child: Card(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 170,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 70,
                                      height: 100,
                                      child: exampleDoc.image.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                                return const Icon(Icons.error);
                                              },
                                            )
                                          : const Icon(
                                              Icons.image_not_supported),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                              'Scan-Datum: ${formatScanDate(exampleDoc.scanDate)}'),
                                          Text(
                                              'Scan-Uhrzeit: ${formatScanTime(exampleDoc.scanDate)}'),
                                          Text(
                                              'Sprache: ${exampleDoc.language}'),
                                          Text('Seitenzahl: $pageCount'),
                                          // const SizedBox(height: 8.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
  }
}
