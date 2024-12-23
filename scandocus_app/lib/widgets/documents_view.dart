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
  bool activeFilter = false;
  bool noFilteredDocs = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDocuments();
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
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);
    final allDocuments = documentProvider.allDocuments;

    final filteredDocuments = await ApiService().getSolrData(
      startDate: filters['startDate'],
      endDate: filters['endDate'],
      startTime: filters['startTime'],
      endTime: filters['endTime'],
      language: filters['language'],
      startPage: filters['startPage'],
      endPage: filters['endPage'],
    );

    print("FILTERED DOCS");
    print(filteredDocuments);

    final int? startPage = int.tryParse(filters['startPage'] ?? '');
    final int? endPage = int.tryParse(filters['endPage'] ?? '');

    List<Document> filteredDocs = [];

    if ((startPage != null && startPage > 0 ||
        endPage != null && endPage > 0)) {
      for (var doc in filteredDocuments) {
        int? totalpageCount =
            int.tryParse(showTotalPageCount(doc, allDocuments));

        print(totalpageCount);

        if (totalpageCount! >= startPage! && totalpageCount <= endPage!) {
          filteredDocs.add(doc);
        }
      }
    } else {
      filteredDocs = filteredDocuments;
    }

    if (mounted) {
      if (filteredDocs.isEmpty) {
        noFilteredDocs = true;
      } else {
        noFilteredDocs = false;
      }

      Provider.of<DocumentProvider>(context, listen: false)
          .applyFilters(filteredDocs, filters);
    }
  }

  void resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _startTime = null;
      _endTime = null;
      selectedLanguage = null;
      startSelectedPages = null;
      endSelectedPages = null;
      activeFilter = false;
    });
  }

  Future<void> searchDocuments(String searchTerm) async {
    try {
      // Ergänze Wildcards zu der Suchanfrage, um die Teilwortsuche zu ermöglichen
      String searchQuery = "*$searchTerm*";

      final documents = await ApiService()
          .searchDocuments(searchQuery); // Rufe die Ergebnisse ab

      print("GEFILTERTE DOCUMENTS");
      print(documents);

      if (mounted) {
        // Aktualisiere die Dokumente im Provider
        Provider.of<DocumentProvider>(context, listen: false)
            .updateSearchedDocuments(documents);
      }
    } catch (e) {
      print("Fehler bei der Suche: $e");
    }
  }

  TextSpan highlightText(String text, String searchTerm) {
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
      ),
    );

    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    if (!originalText.contains(matches)) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    final index = originalText.indexOf(matches);
    final beforeMatch = text.substring(0, index);
    final match = text.substring(index, index + searchTerm.length);
    final afterMatch = text.substring(index + searchTerm.length);

    return TextSpan(
      children: [
        TextSpan(text: beforeMatch, style: quicksandTextStyle),
        TextSpan(
          text: match,
          style: quicksandTextStyle.copyWith(
              backgroundColor: Color.fromARGB(255, 60, 221, 121),
              color: Color(0xFF202124),
              fontWeight: FontWeight.bold),
        ),
        TextSpan(text: afterMatch, style: quicksandTextStyle),
      ],
    );
  }

  bool containsSearchTerm(String text, String searchTerm) {
    return text.toLowerCase().contains(searchTerm.toLowerCase());
  }

  TextSpan getHighlightedSnippetWithHighlight(
      String text, String searchTerm, TextStyle baseStyle) {
    // Berechne den hervorgehobenen Ausschnitt
    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    if (!originalText.contains(matches)) {
      return TextSpan(text: '', style: baseStyle);
    }

    final index = originalText.indexOf(matches);
    final start = (index - 10 > 0) ? index - 10 : 0;
    final end = (index + matches.length + 10 < text.length)
        ? index + matches.length + 10
        : text.length;

    final snippet = text.substring(start, end);

    // Teile den Ausschnitt in vor, Treffer, und nach dem Suchbegriff
    final snippetLower = snippet.toLowerCase();
    final matchIndex = snippetLower.indexOf(matches);

    final beforeMatch = snippet.substring(0, matchIndex);
    final match = snippet.substring(matchIndex, matchIndex + searchTerm.length);
    final afterMatch = snippet.substring(matchIndex + searchTerm.length);

    // Erstelle ein TextSpan mit Markierung
    return TextSpan(
      children: [
        TextSpan(text: '...', style: baseStyle),
        TextSpan(text: beforeMatch, style: baseStyle),
        TextSpan(
          text: match,
          style: baseStyle.copyWith(
              backgroundColor: Color.fromARGB(255, 60, 221, 121),
              color: Color(0xFF202124),
              fontWeight: FontWeight.bold),
        ),
        TextSpan(text: afterMatch, style: baseStyle),
        TextSpan(text: '...', style: baseStyle),
      ],
    );
  }

  String formatScanDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String formatScanTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('HH:mm').format(dateTime);
  }

  String convertDateToString(DateTime date, bool isEndDate) {
    //for showing all docs from start to end, set time to 23:59:59:999
    if (isEndDate) {
      date = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    }
    // Formatieren des Datums in ISO 8601 (UTC-Zeit)
    String isoFormattedDate = date.toIso8601String();
    String isoFormattedDateZ = "${isoFormattedDate}Z";

    // Ausgabe: "2024-12-04T00:00:00.000Z"
    print(isoFormattedDateZ);

    return isoFormattedDateZ;
  }

  String convertTimeToString(TimeOfDay time) {
    final String formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Ausgabe: "17:15" (wenn die Zeit 17:15 ist)
    print(formattedTime);

    return formattedTime;
  }

  String showTotalPageCount(Document filteredDoc, List<Document> allDocuments) {
    // Filtert alle Dokumente mit demselben Dateinamen
    final matchingDocuments =
        allDocuments.where((doc) => doc.fileName == filteredDoc.fileName);

    // Gibt die Anzahl der gefundenen Dokumente zurück
    return matchingDocuments.length.toString();
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

    groupedDocuments.forEach((fileName, docs) {
      docs.sort((a, b) => b.scanDate.compareTo(a.scanDate));
    });

    // Erstelle eine Liste aus den gruppierten Dokumenten
    final uniqueDocuments = groupedDocuments.entries
        .map((entry) => {
              "fileName": entry.key,
              "count": entry.value.length,
              "exampleDoc":
                  entry.value.first, // Ein Beispiel-Dokument für Details
              "scanDate": entry.value.first.scanDate,
            })
        .toList();

    uniqueDocuments.sort((a, b) {
      // Sicherstellen, dass scanDate als String vorliegt
      String scanDateA = a['scanDate'] as String;
      String scanDateB = b['scanDate'] as String;

      // Vergleichen der Strings lexikografisch
      return scanDateB.compareTo(scanDateA); // Neueste zuerst (absteigend)
    });

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
                    icon: Icon(Icons.filter_alt,
                        color: !activeFilter
                            ? Color.fromARGB(219, 11, 185, 216)
                            : Color.fromARGB(255, 60, 221, 121)),
                    onPressed: () async {
                      // Zeige den Dialog an und erhalte die Rückgabewerte
                      final result =
                          await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        backgroundColor: Color(0xFF202124),
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16.0)),
                        ),
                        builder: (BuildContext context) {
                          return ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16.0),
                            ),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              color: Colors.transparent,
                              child: FilterDialog(
                                //return current values to filterDialog
                                initialStartDate: _startDate,
                                initialEndDate: _endDate,
                                initialStartTime: _startTime,
                                initialEndTime: _endTime,
                                initialLanguage: selectedLanguage,
                                initialStartPageNumber: startSelectedPages,
                                initialEndPageNumber: endSelectedPages,
                              ),
                            ),
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

                          if (result.isNotEmpty) {
                            activeFilter = true;
                          } else {
                            activeFilter = false;
                          }
                        });

                        applyFilters({
                          if (result['startDate'] != null)
                            'startDate':
                                convertDateToString(result['startDate'], false),
                          if (result['endDate'] != null)
                            'endDate':
                                convertDateToString(result['endDate'], true),
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
              : !noFilteredDocs
                  ? ListView.builder(
                      itemCount: uniqueDocuments.length,
                      itemBuilder: (context, index) {
                        final documentProvider = Provider.of<DocumentProvider>(
                            context,
                            listen: false);
                        final allDocuments = documentProvider.allDocuments;

                        final docInfo = uniqueDocuments[index];
                        final fileName = docInfo["fileName"] as String;
                        final pageCount = docInfo["count"] as int;
                        final exampleDoc = docInfo["exampleDoc"] as Document;

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
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirm) {
                                  // Dokument löschen, wenn bestätigt
                                  apiService.deleteManyDocsFromSolr(
                                      exampleDoc.fileName);

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
                                      builder: (context) =>
                                          DocumentPageOvereview(
                                        fileName: fileName,
                                        searchTerm: searchController.text,
                                      ),
                                    ),
                                  ).then((_) {
                                    searchController.clear();
                                    resetFilters();
                                    loadDocuments();
                                  });
                                },
                                child: SizedBox(
                                  height: 200,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          width: 90,
                                          height: 200,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
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
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
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
                                              RichText(
                                                text: highlightText(fileName,
                                                    searchController.text),
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
                                              Text(
                                                  'Seitenzahl: ${showTotalPageCount(exampleDoc, allDocuments)}',
                                                  style: quicksandTextStyle),
                                              // Highlighted matching text snippet
                                              if (searchController
                                                      .text.isNotEmpty &&
                                                  containsSearchTerm(
                                                      exampleDoc.docText
                                                          .toString(),
                                                      searchController.text))
                                                RichText(
                                                  text:
                                                      getHighlightedSnippetWithHighlight(
                                                    exampleDoc.docText
                                                        .toString(),
                                                    searchController.text,
                                                    quicksandTextStyle.copyWith(
                                                        color: Colors.white),
                                                  ),
                                                  maxLines:
                                                      1, // Begrenze die Anzahl der Zeilen
                                                  overflow: TextOverflow
                                                      .ellipsis, // Zeigt "..." an, wenn der Text abgeschnitten wird
                                                ),
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
                    )
                  : Center(
                      child: Text(
                        'Keine Dokumente vorhanden.',
                        style: GoogleFonts.quicksand(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
