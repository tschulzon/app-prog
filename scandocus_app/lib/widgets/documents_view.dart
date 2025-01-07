import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scandocus_app/models/document.dart';
import 'package:provider/provider.dart';

import '../screens/doc_page_overview.dart';
import '../services/api_service.dart';
import '../widgets/filter_dialog.dart';
import '../utils/document_provider.dart';
import '../config.dart';

/// This is the [DocumentsView] Widget, which displays all documents in a list retrieved from Solr
/// It is a stateful widget, meaning the widget can have states that change over time
class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  // A flag to indicate if the documents are still loading
  bool isLoading = true;

  // Variables to save values from the filter dialog
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? selectedLanguage;
  int? startSelectedPages;
  int? endSelectedPages;
  bool activeFilter = false;
  bool noFilteredDocs = false;

  // Controller for the search bar, allowing the user to search by filename or specific content
  final TextEditingController searchController = TextEditingController();

  // Initializes the states when the page is first rendered
  @override
  void initState() {
    super.initState();
    loadDocuments(); // Load the documents when the widget is initialized
  }

  // The dispose method clears all controllers when the page is closed to free up memory
  @override
  void dispose() {
    searchController.clear();
    super.dispose();
  }

  // Method for fetching all existing documents from Solr and saving them
  // in the Document Provider so that we can interact with the current documents
  Future<void> loadDocuments() async {
    try {
      // Fetch documents from the Solr API
      final fetchedDocuments = await ApiService().getSolrData();

      // Update the DocumentProvider with the fetched documents if the widget is still mounted
      if (mounted) {
        Provider.of<DocumentProvider>(context, listen: false)
            .setDocuments(fetchedDocuments);
      }

      // Update the loading state to indicate the documents have been loaded
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Dokumente: $e");
    }
  }

  // Method for fetching all documents with filteroptions the user used
  void applyFilters(Map<String, String> filters) async {
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);

    // Save all documents, regardless of the applied filters,
    // to show the count of pages for every document
    final allDocuments = documentProvider.allDocuments;

    // Fetch documents that match the filter options from the API
    final filteredDocuments = await ApiService().getSolrData(
      startDate: filters['startDate'],
      endDate: filters['endDate'],
      startTime: filters['startTime'],
      endTime: filters['endTime'],
      language: filters['language'],
      startPage: filters['startPage'],
      endPage: filters['endPage'],
    );

    // Convert the string page numbers to integers for processing
    // In the filter dialog, the user can filter by the total page count of a document,
    // but Solr can only search for specific page numbers. We want to filter based on the total
    // page count, so a custom filter algorithm is applied here
    final int? startPage = int.tryParse(filters['startPage'] ?? '');
    final int? endPage = int.tryParse(filters['endPage'] ?? '');

    List<Document> filteredDocs = [];

    // Check if the start and end page values are provided. If not, just use the filtered documents
    if ((startPage != null && startPage > 0 ||
        endPage != null && endPage > 0)) {
      // If page filters are applied, we check each filtered document to see if its total page count
      // is within the range of startPage and endPage. If it is, add it to the new filtered list
      for (var doc in filteredDocuments) {
        // Get the total page count for each document with the specific function
        int? totalpageCount =
            int.tryParse(showTotalPageCount(doc, allDocuments));

        // If the document's total page count is within the range, add it to the list
        if (totalpageCount! >= startPage! && totalpageCount <= endPage!) {
          filteredDocs.add(doc);
        }
      }
    } else {
      // If no page range filters are provided, use the filtered documents as they are
      filteredDocs = filteredDocuments;
    }

    // Update the state to show whether no documents were found after applying the filters
    if (mounted) {
      if (filteredDocs.isEmpty) {
        noFilteredDocs = true;
      } else {
        noFilteredDocs = false;
      }

      // Set the filtered documents also in the provider
      Provider.of<DocumentProvider>(context, listen: false)
          .applyFilters(filteredDocs, filters);
    }
  }

  // Method to search and display documents based on the user's search term
  Future<void> searchDocuments(String searchTerm) async {
    try {
      // Add wildcards to the query to enable partial matching for the search term
      String searchQuery = "*$searchTerm*";

      // Fetch documents from the API that match the search term
      final documents = await ApiService().searchDocuments(searchQuery);

      // Set the fetched documents also in the provider
      if (mounted) {
        Provider.of<DocumentProvider>(context, listen: false)
            .updateSearchedDocuments(documents);
      }
    } catch (e) {
      print("Fehler bei der Suche: $e");
    }
  }

  // Method to reset all filter values when user returns to the homepage from a subscreen
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

  // Method to highlight a text when searching for a specific word
  TextSpan highlightText(String text, String searchTerm) {
    // Define the style for the text, using the Google Quicksand font
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
      ),
    );

    // Convert both the search term and original text to lowercase for case-insensitive matching
    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    // If the original text does not contain the search term, return the text with the defined style
    if (!originalText.contains(matches)) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    // Find the index of the first occurrence of the search term in the text
    final index = originalText.indexOf(matches);

    // Split the text into three parts: before the match, the matched text, and after the match
    final beforeMatch = text.substring(0, index);
    final match = text.substring(index, index + searchTerm.length);
    final afterMatch = text.substring(index + searchTerm.length);

    // Return the text with highlighted match
    return TextSpan(
      children: [
        // Text before match
        TextSpan(text: beforeMatch, style: quicksandTextStyle),
        TextSpan(
          text: match, // Highlighted matched text
          style: quicksandTextStyle.copyWith(
              backgroundColor: Color.fromARGB(255, 60, 221, 121),
              color: Color(0xFF202124),
              fontWeight: FontWeight.bold),
        ),
        // Text after match
        TextSpan(text: afterMatch, style: quicksandTextStyle),
      ],
    );
  }

  // Method to check if a text contains the search term (case-insensitive)
  bool containsSearchTerm(String text, String searchTerm) {
    return text.toLowerCase().contains(searchTerm.toLowerCase());
  }

  // Method to get a snippet of the text with the search term highlighted
  TextSpan getHighlightedSnippetWithHighlight(
      String text, String searchTerm, TextStyle baseStyle) {
    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    // If the search term is not found in the text, return an empty snippet
    if (!originalText.contains(matches)) {
      return TextSpan(text: '', style: baseStyle);
    }

    // Get the starting and ending index for the snippet with a buffer around the match
    final index = originalText.indexOf(matches);
    final start = (index - 10 > 0)
        ? index - 10
        : 0; // Start 10 characters before the match
    final end = (index + matches.length + 10 < text.length)
        ? index + matches.length + 10
        : text.length; // End 10 characters after the match

    // Get the snippet of text around the match
    final snippet = text.substring(start, end);

    // Convert the snippet to lowercase for case-insensitive matching
    final snippetLower = snippet.toLowerCase();
    final matchIndex = snippetLower.indexOf(matches);

    // Split the snippet into three parts: before the match, the match itself, and after the match
    final beforeMatch = snippet.substring(0, matchIndex);
    final match = snippet.substring(matchIndex, matchIndex + searchTerm.length);
    final afterMatch = snippet.substring(matchIndex + searchTerm.length);

    // Return the snippet with the matched term highlighted and ellipses before and after
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

  // Method to format the scan date into a standard date format (dd-MM-yyyy)
  String formatScanDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  // Method to format the scan time into hour and minute format (HH:mm)
  String formatScanTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('HH:mm').format(dateTime);
  }

  // Method to convert a DateTime object to a string, as the scan date in Solr is stored as a string
  // If the date is the end date, it sets the time to 23:59:59.999 to include all documents on the end date
  String convertDateToString(DateTime date, bool isEndDate) {
    if (isEndDate) {
      date = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    }

    // Format the date to ISO 8601 format and append 'Z' to indicate UTC time, e.g., "2024-12-04T00:00:00.000Z"
    String isoFormattedDate = date.toIso8601String();
    String isoFormattedDateZ = "${isoFormattedDate}Z";

    return isoFormattedDateZ;
  }

  // Method to convert a TimeOfDay object to a string, as the scan time in Solr is stored as a string
  // The time is formatted in the "HH:mm" format, e.g., "17:15"
  String convertTimeToString(TimeOfDay time) {
    final String formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  // Method to get the total page count of a document based on its filename
  String showTotalPageCount(Document filteredDoc, List<Document> allDocuments) {
    // Find all documents from the allDocuments list where the filename matches the filtered document's filename
    final matchingDocuments =
        allDocuments.where((doc) => doc.fileName == filteredDoc.fileName);

    // Return the total count of matching documents as a string (representing the total page count)
    return matchingDocuments.length.toString();
  }

  // Method to get all languages of a document based on its filename
  String showAllLanguages(Document filteredDoc, List<Document> allDocuments) {
    // Find all documents from the allDocuments list where the filename matches the filtered document's filename
    final matchingDocuments =
        allDocuments.where((doc) => doc.fileName == filteredDoc.fileName);

    // Create a list to store unique languages from matching documents
    final documentLanguages = [];

    // Loop through every document and check if the language already exists
    // in the list, if not than add it
    for (var doc in matchingDocuments) {
      if (!documentLanguages.contains(doc.language)) {
        documentLanguages.add(doc.language);
      }
    }

    // Combine all unique languages into a single string, separated by commas
    String languagesString = documentLanguages.join(', ');

    // Return the concatenated string of languages
    return languagesString;
  }

  // Building the Document View Widget
  @override
  Widget build(BuildContext context) {
    // Define a TextStyle variable using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    // Get the current list of documents from the provider
    final documentProvider = Provider.of<DocumentProvider>(context);
    final documents = documentProvider.documents;
    final apiService = ApiService();

    // For showing all pages with the same filename in one "document" we will group
    // all this documents in a map
    final groupedDocuments = <String, List<Document>>{};

    // Loop through every document and check if the document with this name already exists
    // in the grouped map, if not than add it
    for (var doc in documents) {
      if (!groupedDocuments.containsKey(doc.fileName)) {
        groupedDocuments[doc.fileName] = [];
      }
      groupedDocuments[doc.fileName]!.add(doc);
    }

    // Sort the documents in each group by scanDate in descending order (newest first)
    groupedDocuments.forEach((fileName, docs) {
      docs.sort((a, b) => b.scanDate.compareTo(a.scanDate));
    });

    // Create a new list with the grouped documents and additional metadata (fileName, count, example document, scanDate)
    final uniqueDocuments = groupedDocuments.entries
        .map((entry) => {
              "fileName": entry.key,
              "count": entry.value.length,
              "exampleDoc": entry
                  .value.first, // Example document to show document details
              "scanDate": entry.value.first.scanDate,
            })
        .toList();

    // Sort the unique documents list by scanDate in descending order (newest first)
    uniqueDocuments.sort((a, b) {
      String scanDateA = a['scanDate'] as String;
      String scanDateB = b['scanDate'] as String;
      return scanDateB.compareTo(scanDateA);
    });

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
          // ClayContainer for my used "Neomorphism" Design Style
          child: ClayContainer(
            depth: 13,
            spread: 5,
            color: baseColor,
            borderRadius: 50,
            // Creating the searchbar with interactive filter icon
            child: TextField(
              style: quicksandTextStyle,
              controller: searchController,
              onChanged: (String value) async {
                if (value.isNotEmpty) {
                  await searchDocuments(value);
                } else {
                  loadDocuments();
                }
              },
              // Style and function of the filter icon
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search,
                      color: Color.fromARGB(219, 11, 185, 216)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_alt,
                        color: !activeFilter
                            ? Color.fromARGB(219, 11, 185, 216)
                            : Color.fromARGB(255, 60, 221, 121)),
                    onPressed: () async {
                      // Show the filter dialog as a ModalBottomSheet and save the returned values after closing it
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
                                // Pass current filter values to the dialog as initial values
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

                      // Handle the returned values if they are not null
                      if (result != null) {
                        setState(() {
                          // Update filter variables based on returned values
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

                        // Use the returned value for fetching documents with these filter
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
        // Empty SizedBox as a placeholder for creating space between two widgets
        SizedBox(height: 5),
        // Build a list to display documents fetched from Solr
        Expanded(
          child: isLoading
              ? Center(
                  child:
                      CircularProgressIndicator()) // Show loading spinner while data is being fetched
              : !noFilteredDocs
                  ? ListView.builder(
                      itemCount: uniqueDocuments
                          .length, // Number of unique documents to display
                      itemBuilder: (context, index) {
                        final documentProvider = Provider.of<DocumentProvider>(
                            context,
                            listen: false);

                        // Retrieve all documents from the provider for page filtering in the filter dialog
                        final allDocuments = documentProvider.allDocuments;

                        // From the uniqueDocuments list (grouped documents), take each document and display it as a list item
                        final docInfo = uniqueDocuments[index];
                        final fileName = docInfo["fileName"] as String;
                        final exampleDoc = docInfo["exampleDoc"]
                            as Document; // Get an example document for display

                        // Construct the URL for the document's image
                        final String imageUrl = '$baseUrl${exampleDoc.image}';

                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 12.0, right: 12.0, top: 15.0),
                          child: ClayContainer(
                            depth: 13,
                            spread: 5,
                            color: baseColor,
                            height: 150,
                            borderRadius: 20,
                            // Dismissible widget allows for swiping an item to delete it
                            child: Dismissible(
                              key: Key(exampleDoc.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                // Show a confirmation dialog asking the user if they are sure about deleting the document
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
                                        // Cancel Button
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: Text('Abbrechen',
                                              style: GoogleFonts.quicksand()),
                                        ),
                                        // Confirm Button
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
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
                                  // Delete document in Solr if user confirmed the dialog
                                  apiService.deleteManyDocsFromSolr(
                                      exampleDoc.fileName);

                                  // Remove the document from the local document provider to update the UI
                                  documentProvider.removeDocument(fileName);

                                  // Provide feedback to the user with a snackbar, confirming the document has been deleted
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Dokument "$fileName" wurde gelöscht')),
                                    );
                                  }
                                }

                                return confirm;
                              },
                              // Container widget for the "Delete-Swipe" background when the user swipes to delete
                              background: Container(
                                color: const Color.fromARGB(255, 123, 42, 36),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 32),
                              ),
                              // GestureDetector to handle tap on an item to navigate to the document overview screen
                              child: GestureDetector(
                                onTap: () async {
                                  // Navigate to the document overview page to display all pages of the document
                                  // Passing necessary values such as the file name and the current search term
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
                                    // After the user returns, reset the search controller and filters, and reload all documents
                                    searchController.clear();
                                    resetFilters();
                                    loadDocuments();
                                  });
                                },
                                // Create the list item UI for each document, showing the document picture and metadata
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
                                                      // If the picture can not be loaded, then show an error icon
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
                                                  'Sprache: ${showAllLanguages(exampleDoc, allDocuments)}',
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
                                                      1, // Show only one line
                                                  overflow: TextOverflow
                                                      .ellipsis, // Show "..." if line is too long
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
                  // If no documents can't be shown, then show this default text
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
