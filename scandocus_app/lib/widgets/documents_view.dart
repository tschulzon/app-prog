import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'package:scandocus_app/models/document.dart';
import '../screens/doc_page_overview.dart';
import '../services/api_service.dart';
import '../widgets/filter_dialog.dart';

import 'package:provider/provider.dart';
import '../utils/document_provider.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  // List<Document> documents = [];
  bool isLoading = true;
  // Variablen zum Speichern der Filterwerte
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? selectedLanguage;
  int? startSelectedPages;
  int? endSelectedPages;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDocuments();
    // Nur Dokumente laden, wenn es keine gefilterten Dokumente gibt
    // if (Provider.of<DocumentProvider>(context, listen: false)
    //     .documents
    //     .isEmpty) {
    //   loadDocuments(); // Initialer Dokumenten-Load
    // }
  }

  @override
  void dispose() {
    searchController.clear(); // Text in der Suchleiste leeren
    super.dispose();
  }

  Future<void> loadDocuments() async {
    try {
      final fetchedDocuments = await ApiService().getSolrData();

      if (mounted) {
        Provider.of<DocumentProvider>(context, listen: false)
            .setDocuments(fetchedDocuments);
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Dokumente: $e");
    }
  }

  void applyFilters(Map<String, String> filters) async {
    final filteredDocuments = await ApiService().getSolrData(
      startDate: filters['startDate'],
      endDate: filters['endDate'],
      startTime: filters['startTime'],
      endTime: filters['endTime'],
      // startPage: filters['startPage'],
      // endPage: filters['endPage'],
      language: filters['language'],
    );

    final int? startPage = int.tryParse(filters['startPage'] ?? '');
    final int? endPage = int.tryParse(filters['endPage'] ?? '');

    List<Document> documentsToDisplay;

    // Gruppiert Dokumente anhand ihrer Dateinamen und zählt die Gesamtanzahl der Seiten.
    Map<String, List<Document>> documentGroups = {};
    for (var document in filteredDocuments) {
      final fileName = document
          .fileName; // Nehmen wir an, `fileName` ist der Dateiname des Dokuments.
      if (!documentGroups.containsKey(fileName)) {
        documentGroups[fileName] = [];
      }
      documentGroups[fileName]!.add(document);
    }

    List<Document> filteredList = [];

    // Überprüfen, ob Start- oder Endseite angegeben ist und Dokumente filtern.
    if (startPage != null && startPage > 0 || endPage != null && endPage > 0) {
      for (var entry in documentGroups.entries) {
        String fileName = entry.key;
        List<Document> documents = entry.value;

        // Zählt die Gesamtanzahl der Seiten für das Dokument anhand der Gruppenanzahl.
        int totalPageCount = documents.length;

        bool matchesPageRange = true;

        // Überprüfen, ob eine Startseite angegeben wurde.
        if (startPage != null && startPage > 0) {
          matchesPageRange = matchesPageRange && (totalPageCount >= startPage);
        }

        // Überprüfen, ob eine Endseite angegeben wurde.
        if (endPage != null && endPage > 0) {
          matchesPageRange = matchesPageRange && (totalPageCount <= endPage);
        }

        // Wenn das Dokument die Bedingungen erfüllt, füge alle Vorkommen hinzu.
        if (matchesPageRange) {
          filteredList.addAll(documents);
        }
      }
    } else {
      // Wenn keine Seitenzahlen angegeben sind, verwenden wir die ursprünglichen gefilterten Dokumente.
      filteredList = filteredDocuments;
    }
    if (mounted) {
      Provider.of<DocumentProvider>(context, listen: false)
          .applyFilters(filteredList, filters);
    }
  }

  Future<void> searchDocuments(String searchTerm) async {
    try {
      // Ergänze Wildcards zu der Suchanfrage, um die Teilwortsuche zu ermöglichen
      String searchQuery = "*$searchTerm*";

      final documents = await ApiService()
          .searchDocuments(searchQuery); // Rufe die Ergebnisse ab

      if (mounted) {
        // Aktualisiere die Dokumente im Provider
        Provider.of<DocumentProvider>(context, listen: false)
            .updateSearchedDocuments(documents);
      }
    } catch (e) {
      print("Fehler bei der Suche: $e");
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

  String convertDateToString(DateTime date) {
    // Formatieren des Datums in ISO 8601 (UTC-Zeit)
    String isoFormattedDate = date.toUtc().toIso8601String();

    // Ausgabe: "2024-12-04T00:00:00.000Z"
    print(isoFormattedDate);

    return isoFormattedDate;
  }

  String convertTimeToString(TimeOfDay time) {
    final String formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Ausgabe: "17:15" (wenn die Zeit 17:15 ist)
    print(formattedTime);

    return formattedTime;
  }

  TimeOfDay selectedTime = TimeOfDay.now(); // Aktuelle Zeit initialisieren

  @override
  Widget build(BuildContext context) {
    //Fontstyling variable
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );
    // Zugriff auf den Provider
    final documentProvider = Provider.of<DocumentProvider>(context);
    final documents = documentProvider.documents;
    final apiService = ApiService();
    Color baseColor = Color(0xFF202124);
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

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
          child: ClayContainer(
            // emboss: true,
            depth: 13,
            spread: 5,
            color: baseColor,
            borderRadius: 50,
            child: TextField(
              style: quicksandTextStyle,
              controller: searchController,
              onChanged: (String value) async {
                print("Suchabfrage: $value");
                if (value.isNotEmpty) {
                  // Rufe die Methode auf, um eine Suchanfrage zu stellen und die Ergebnisse zu aktualisieren.
                  await searchDocuments(value);
                } else {
                  loadDocuments();
                }
              },
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search,
                      color: Color.fromARGB(219, 11, 185, 216)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_alt,
                        color: Color.fromARGB(219, 11, 185, 216)),
                    onPressed: () async {
                      // Zeige den Dialog an und erhalte die Rückgabewerte
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (BuildContext context) {
                          // Übergebe die aktuellen Werte an den FilterDialog
                          return FilterDialog(
                            initialStartDate: _startDate,
                            initialEndDate: _endDate,
                            initialStartTime: _startTime,
                            initialEndTime: _endTime,
                            initialLanguage: selectedLanguage,
                            initialStartPageNumber: startSelectedPages,
                            initialEndPageNumber: endSelectedPages,
                          );
                        },
                      );

                      // Verarbeite die Rückgabewerte, wenn sie nicht null sind
                      if (result != null) {
                        setState(() {
                          if (result['startDate'] != null) {
                            _startDate = result['startDate'];
                          } else {
                            _startDate = null;
                          }

                          if (result['endDate'] != null) {
                            _endDate = result['endDate'];
                          } else {
                            _endDate = null;
                          }

                          if (result['startTime'] != null) {
                            _startTime = result['startTime'];
                          } else {
                            _startTime = null;
                          }

                          if (result['endTime'] != null) {
                            _endTime = result['endTime'];
                          } else {
                            _endTime = null;
                          }

                          if (result['selectedLanguage'] != null) {
                            selectedLanguage = result['selectedLanguage'];
                          } else {
                            selectedLanguage = null;
                          }

                          if (result['startSelectedPages'] != null) {
                            startSelectedPages = result['startSelectedPages'];
                          } else {
                            startSelectedPages = null;
                          }

                          if (result['endSelectedPages'] != null) {
                            endSelectedPages = result['endSelectedPages'];
                          } else {
                            endSelectedPages = null;
                          }
                        });

                        applyFilters({
                          if (result['startDate'] != null)
                            'startDate':
                                convertDateToString(result['startDate']),
                          if (result['endDate'] != null)
                            'endDate': convertDateToString(result['endDate']),
                          if (result['startTime'] != null)
                            'startTime':
                                convertTimeToString(result['startTime']),
                          if (result['endTime'] != null)
                            'endTime': convertTimeToString(result['endTime']),
                          if (result['selectedLanguage'] != null)
                            'language': result['selectedLanguage'],
                          if (result['startSelectedPages'] != null)
                            'startPage':
                                result['startSelectedPages'].toString(),
                          if (result['endSelectedPages'] != null)
                            'endPage': result['endSelectedPages'].toString(),
                        });
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Name / Text suchen",
                  hintStyle: quicksandTextStyle),
            ),
          ),
        ),
        // Die Suchleiste
        SizedBox(height: 5),
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
                    final String imageUrl =
                        'http://192.168.178.193:3000${exampleDoc.image}'; // Bild-URL
                    // final String imageUrl =
                    //     'http://192.168.2.171:3000${exampleDoc.image}';
                    // final String imageUrl =
                    //     'http://192.168.178.49:3000${exampleDoc.image}';

                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 12.0, right: 12.0, top: 15.0),
                      child: ClayContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        height: 150,
                        // width: 150,
                        borderRadius: 20,
                        child: Dismissible(
                          key: Key(exampleDoc.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final bool confirm = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: baseColor,
                                  content: Text(
                                      "Möchten Sie dieses Dokument wirklich löschen? Dies kann nicht rückgängig gemacht werden.",
                                      style: GoogleFonts.quicksand(
                                        textStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      )),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(false); // Abbrechen
                                      },
                                      child: Text('Abbrechen',
                                          style: GoogleFonts.quicksand()),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(true); // Abbrechen
                                      },
                                      child: Text('Löschen',
                                          style: GoogleFonts.quicksand(
                                            textStyle: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 173, 57, 49),
                                                fontWeight: FontWeight.w600),
                                          )),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm) {
                              // Dokument löschen, wenn bestätigt
                              apiService
                                  .deleteManyDocsFromSolr(exampleDoc.fileName);

                              documentProvider.removeDocument(fileName);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Dokument "$fileName" wurde gelöscht')),
                              );
                            }

                            return confirm; // Löschen nur, wenn bestätigt
                          },
                          background: Container(
                            color: const Color.fromARGB(255, 123, 42, 36),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 32),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentPageOvereview(
                                    fileName: fileName,
                                  ),
                                ),
                              ).then((_) {
                                searchController.clear();
                                loadDocuments(); // Suchleiste und Dokumente zurücksetzen
                              });
                            },
                            child: SizedBox(
                              height: 170,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      width: 90,
                                      height: 160,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              offset: Offset(0, 4),
                                              blurRadius: 4,
                                            )
                                          ]),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        child: exampleDoc.image.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
                                                  return const Icon(
                                                      Icons.error);
                                                },
                                              )
                                            : const Icon(
                                                Icons.image_not_supported),
                                      ),
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
                                            style: GoogleFonts.quicksand(
                                              textStyle: TextStyle(
                                                color: Color.fromARGB(
                                                    219, 11, 185, 216),
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                              'Scan-Datum: ${formatScanDate(exampleDoc.scanDate)}',
                                              style: quicksandTextStyle),
                                          Text(
                                              'Scan-Uhrzeit: ${formatScanTime(exampleDoc.scanDate)}',
                                              style: quicksandTextStyle),
                                          Text(
                                              'Sprache: ${exampleDoc.language}',
                                              style: quicksandTextStyle),
                                          Text('Seitenzahl: $pageCount',
                                              style: quicksandTextStyle),
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
