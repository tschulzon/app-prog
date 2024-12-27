import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/document.dart';
import '../screens/ocr_page.dart';
import '../screens/camera_page.dart';
import '../services/api_service.dart';
import '../utils/document_provider.dart';

/// This is the [Detailpage] Screen, it displays the document page selected by the user
/// It provides the document page image and its scanned content
///
/// Features:
/// - Displays the document image.
/// - Shows the scanned text with matched terms highlighted, if a search term is provided.
/// - Allows the user to rescan the text if unsatisfied with the current scan.
/// - Enables replacing the current image with a new one and rescanning the text.
/// - Provides an option to delete the current document page.
/// - Supports swiping between pages (left or right) to navigate through other document pages
///
/// This screen is implemented as a stateful widget to handle dynamic interactions and updates
class Detailpage extends StatefulWidget {
  /// Parameters:
  /// - [document]: The document currently being viewed
  /// - [searchTerm] (optional): /// An search term for highlighting within the document's scanned text
  final Document document;
  final String? searchTerm;

  /// Constructor, which initializes optional parameters for flexibility
  const Detailpage({super.key, required this.document, this.searchTerm});

  @override
  State<Detailpage> createState() => _DetailpageState();
}

/// State class for the [Detailpage] widget
///
/// Responsibilities:
/// - Manages the document's state, including navigation between pages
/// - Handles search term highlighting within the document text
/// - Provides actions for rescanning text, replacing the image, and deleting the document page
class _DetailpageState extends State<Detailpage> {
  // Variables for managing the current document and optional search term
  late Document doc;
  String? searchTerm;

  // Variables for handling all related document pages, page navigation, and the current page index
  late List<Document> documents = [];
  late PageController pageController;
  int currentIndex = 0;

  // Initialize Variables with values from the parent page
  @override
  void initState() {
    super.initState();

    // Retrieve the document provider to access the current document data
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);

    // Fetch the specific document by its ID, defaulting to the widget's document if not found
    doc = documentProvider.documents.firstWhere(
      (d) => d.id == widget.document.id,
      orElse: () => widget.document,
    );

    // Sort documents after sitenumber to have the correct order
    documentProvider.documents
        .sort((a, b) => a.siteNumber.compareTo(b.siteNumber));

    // Get all documents with the same filename as the current document
    documents = documentProvider.getDocumentsByFileName(doc.fileName);

    // Get the index of the current page within the list of related documents
    currentIndex = documents.indexWhere((d) => d.id == doc.id);

    // Initialize the PageController with the current document's page index
    pageController = PageController(initialPage: currentIndex);

    // Set the search term if provided
    if (widget.searchTerm != null) {
      searchTerm = widget.searchTerm;
    }
  }

  /// Highlights occurrences of the [searchTerm] in the given [text]
  /// If no search term is provided or found, the text is returned unmodified
  TextSpan highlightSearchTerm(String text, String? searchTerm) {
    // Define a TextStyle variable using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    // If the search term is null or empty, return the text with the default style
    if (searchTerm == null || searchTerm.isEmpty) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    // Convert the search term and text to lowercase for case-insensitive matching
    final matches = searchTerm.toLowerCase();
    final originalText = text.toLowerCase();

    // If the search term is not found in the text, return the unmodified text
    if (!originalText.contains(matches)) {
      return TextSpan(text: text, style: quicksandTextStyle);
    }

    // Highlight all occurrences of the search term
    List<TextSpan> textSpans = [];
    int startIndex = 0;

    while (startIndex < text.length) {
      final index = originalText.indexOf(matches, startIndex);

      // If no more matches are found, append the remaining text and exit the loop
      if (index == -1) {
        textSpans.add(TextSpan(
          text: text.substring(startIndex),
          style: quicksandTextStyle,
        ));
        break;
      }

      // Append the text before the match
      if (index > startIndex) {
        textSpans.add(TextSpan(
          text: text.substring(startIndex, index),
          style: quicksandTextStyle,
        ));
      }

      // Append the highlighted match
      textSpans.add(
        TextSpan(
          text: text.substring(index, index + searchTerm.length),
          style: quicksandTextStyle.copyWith(
              backgroundColor: Color.fromARGB(255, 60, 221, 121),
              color: Color(0xFF202124),
              fontWeight: FontWeight.bold),
        ),
      );

      // Update the start index to continue searching after the current match
      startIndex = index + searchTerm.length;
    }

    return TextSpan(children: textSpans);
  }

  // This build method creates the widget tree for the current screen
  @override
  Widget build(BuildContext context) {
    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    // Define a TextStyle variable using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return Scaffold(
      backgroundColor: baseColor,
      // Creating an AppBar with sitenumber as title and icon customization
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text('Seite ${documents[currentIndex].siteNumber}'),
        titleTextStyle: quicksandTextStyleTitle,
        centerTitle: true,
        backgroundColor: baseColor,
        // Color of back button/icon
        iconTheme: const IconThemeData(
          color: Color.fromARGB(219, 11, 185, 216),
        ),
      ),
      // The body displays either a PageView or a fallback message if no documents are available
      body: documents.isNotEmpty
          // PageView Builder allows horizontal swiping between document pages
          ? PageView.builder(
              controller: pageController,
              itemCount: documents.length,
              onPageChanged: (pageIndex) {
                // Updates the current index when the user swipes to a new page
                setState(() {
                  currentIndex = pageIndex;
                });
              },
              // Builds each page item, which includes the document image and scanned text
              itemBuilder: (context, index) {
                final currentDoc = documents[index];

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          // Displays the document page's image within a styled container
                          ClayContainer(
                            depth: 13,
                            spread: 5,
                            color: baseColor,
                            borderRadius: 20,
                            width: 300.0,
                            height: 400.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: currentDoc.image.isNotEmpty
                                  // Dynamically loads the image from a network source
                                  ? Image.network(
                                      'http://192.168.178.193:3000${currentDoc.image}',
                                      width: 300,
                                      height: 400,
                                      fit: BoxFit.contain,

                                      // Handles cases where the image fails to load
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    )
                                  : const Icon(Icons
                                      .image_not_supported), // Fallback icon if no image exists
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Displays the scanned text in a styled container
                          ClayContainer(
                            depth: 13,
                            spread: 5,
                            color: baseColor,
                            borderRadius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "Erkannter Text: ",
                                    style: GoogleFonts.quicksand(
                                      textStyle: TextStyle(
                                        color:
                                            Color.fromARGB(219, 11, 185, 216),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // Displays the scanned text, highlighting search terms and enabling selection for copying the text
                                  SelectableText.rich(
                                    TextSpan(
                                      children: [
                                        highlightSearchTerm(
                                          currentDoc.docText
                                              .join(
                                                  ' ') // Combines text fragments into a single string
                                              .replaceAll('\n',
                                                  ' '), // Replaces line breaks for consistent display
                                          searchTerm, // Highlights the search term if provided
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  )
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
            )
          // Fallback message when no documents are available
          : Center(
              child: Text('Keine Dokumente vorhanden.'),
            ),

      // Bottom navigation bar with actions for the current document page
      // Passes all document pages and the current index for handling actions
      bottomNavigationBar:
          BottomButtons(page: documents[currentIndex], documents: documents),
    );
  }
}

// Bottom Buttons have no states, so we use a stateless widget
// This widget provides three primary actions for the document page:
// - Rescanning the text
// - Replacing the document image
// - Deleting the current document page
class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.page, required this.documents});

  // Variables to store all document pages and the current page
  final List<Document> documents;
  final Document page;

  @override
  Widget build(BuildContext context) {
    // Create an instance of the API service for interacting with the backend
    final apiService = ApiService();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 70.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // Button for rescanning the text
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                color: Color(0xFF202124),
                tooltip: 'Dokument nochmal scannen',
                icon: const Icon(Icons.document_scanner),
                onPressed: () {
                  // Navigate to the OCR processing screen to rescan the document text and pass relevant data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OcrProcessView(
                          existingImage: page.image,
                          existingFilename: page.fileName,
                          existingId: page.id,
                          existingPage: page.siteNumber),
                    ),
                  );
                },
              ),
            ),
          ),
          // Button for replacing the image of the current document page
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              //
              child: IconButton(
                color: Color(0xFF202124),
                tooltip: 'Dokument ersetzen',
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: () {
                  // Navigate to the camera screen to capture a new document image
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakePictureScreen(
                        existingFilename: page.fileName,
                        replaceImage: true,
                        existingId: page.id,
                        existingPage: page.siteNumber,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Button for deleting the current document page
          ClayContainer(
            depth: 10,
            spread: 10,
            color: Color(0xFF202124),
            borderRadius: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(219, 11, 185, 216),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                color: Color(0xFF202124),
                tooltip: 'Seite löschen',
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // Remove the current page from the local list of document pages
                  documents.removeWhere((page) => page.id == this.page.id);

                  // Delete the current document page from the Solr server
                  await apiService.deleteDocFromSolr(page.id, page.fileName);

                  // Show a snackbar to inform the user that the page has been deleted
                  final SnackBar snackBar = SnackBar(
                    content: const Text('Dokument wurde gelöscht!'),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    // Update the page numbers for the remaining document pages
                    for (int i = 0; i < documents.length; i++) {
                      documents[i].siteNumber = i + 1;
                    }

                    // Navigate back and pass the updated documents list
                    Navigator.pop(context, documents);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
