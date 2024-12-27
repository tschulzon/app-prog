import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/services/api_service.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/document_provider.dart';
import '../models/document.dart';

/// This is the [DocumentPageOvereview] Screen, it displays all pages of a selected document when the user
/// taps on it from the homepage. The pages are presented in a grid view, each showing:
/// - The document image
/// - The page number
/// - A part of the scanned text (if available)
///
/// Features of this screen include:
/// - Reordering Pages: Users can reorder pages by holding and dragging them to a new position
/// - Navigation to Detail Page: Tapping on a page navigates the user to a detailed view
///   where they can see the scanned text, remove the page, replace the image or scan the text again.
///
/// This screen is implemented as a stateful widget, meaning it can maintain and update its state
/// over its lifecycle based on user interactions or other dynamic factors.
class DocumentPageOvereview extends StatefulWidget {
  /// Parameters:
  /// - [fileName]: The name of the document being displayed
  /// - [searchTerm] (optional): A term used to filter or highlight specific pages within the document
  final String fileName;
  final String? searchTerm;

  /// Constructor, which initializes optional parameters for flexibility
  const DocumentPageOvereview({
    super.key,
    required this.fileName,
    this.searchTerm,
  });

  @override
  State<DocumentPageOvereview> createState() => _DocumentPageOvereviewState();
}

/// State class for the [DocumentPageOvereview] widget
/// Handles the logic for highlighting a matching searchterm in
/// the part of the scanned text and the reordering of the pages
class _DocumentPageOvereviewState extends State<DocumentPageOvereview> {
  // Variable to store the search term used for highlighting matches within the document text
  late String? searchTerm;

  // Initialize Variables with values from the parent page, default is an empty string
  @override
  void initState() {
    super.initState();
    searchTerm = widget.searchTerm ?? "";
  }

  /// This method is called when the widget's dependencies change
  /// Used here to refresh the document data when the user navigates to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
  }

  // Method to get a snippet of the text with the search term highlighted
  TextSpan getHighlightedSnippetWithHighlight(
      String text, String searchTerm, TextStyle baseStyle) {
    // Convert the search term to lowercase for a case-insensitive match
    final matches = searchTerm.toLowerCase();

    // Split the text into lines for processing
    final lines = text.split('\n');
    String? matchingLine;

    // Locate the first line containing the search term
    for (var line in lines) {
      if (line.toLowerCase().contains(matches)) {
        matchingLine = line;
        break; // Only consider the first matching line
      }
    }

    // If no match is found, return an empty TextSpan with the base style
    if (matchingLine == null) {
      return TextSpan(text: '', style: baseStyle);
    }

    // Find the index of the match and calculate the snippet's range
    final index = matchingLine.toLowerCase().indexOf(matches);
    final start = (index - 8 > 0)
        ? index - 8
        : 0; // Include 8 characters before the match
    final end = (index + matches.length + 8 < matchingLine.length)
        ? index + matches.length + 8
        : matchingLine.length; // Include 8 characters after the match

    final snippet = matchingLine.substring(start, end);

    // Split the snippet into parts: before the match, the match, and after the match
    final snippetLower = snippet.toLowerCase();
    final matchIndex = snippetLower.indexOf(matches);

    final beforeMatch = snippet.substring(0, matchIndex);
    final match = snippet.substring(matchIndex, matchIndex + searchTerm.length);
    final afterMatch = snippet.substring(matchIndex + searchTerm.length);

    // Create a TextSpan with the match highlighted
    return TextSpan(
      children: [
        TextSpan(text: '...', style: baseStyle),
        TextSpan(text: beforeMatch, style: baseStyle),
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

  // This build method creates the widget tree for the current screen
  @override
  Widget build(BuildContext context) {
    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    // Define various TextStyle variables using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleDocText = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleSiteNumbers = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    // Using the Consumer widget to listen for updates to the DocumentProvider and always get the latest documents
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        // Fetch all document pages for the specific file based on the filename passed from the homepage
        List<Document> documents =
            documentProvider.getDocumentsByFileName(widget.fileName);

        final numberDocuments = documents.length;

        return Scaffold(
          backgroundColor: baseColor,
          // Creating an AppBar with title and icon customization
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: Text(widget.fileName),
            titleTextStyle: quicksandTextStyleTitle,
            centerTitle: true,
            backgroundColor: baseColor,
            // Color of back button/icon
            iconTheme: const IconThemeData(
              color: Color.fromARGB(219, 11, 185, 216),
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),

                /// Using the [ReorderableGridView] package to display documents in a grid view
                /// where users can reorder the pages by dragging them to another position
                child: ReorderableGridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, // Space between columns
                  mainAxisSpacing: 20, // Space between rows
                  crossAxisCount: 2, // 2 Columns in the grid
                  childAspectRatio: 0.7, // Height of each grid item
                  // Logic for handling reordering of document pages in the grid
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      // Remove the document from its old position and insert it at the new position
                      final movedDoc = documents.removeAt(oldIndex);
                      documents.insert(newIndex, movedDoc);

                      // Update the site numbers for each document page after reordering
                      for (int i = 0; i < documents.length; i++) {
                        documents[i].siteNumber = i + 1;
                      }

                      // Update the list of documents in the provider
                      documentProvider.setDocuments(documents);

                      // Update the page numbers in Solr if there is a reorder
                      // based on whether the document is moved up or down
                      if (oldIndex < newIndex) {
                        // Moved document to the bottom
                        for (int i = oldIndex; i <= newIndex; i++) {
                          ApiService().updatePageNumber(documents[i].id, i + 1);
                        }
                      } else {
                        // Moved document to the top
                        for (int i = newIndex; i <= oldIndex; i++) {
                          ApiService().updatePageNumber(documents[i].id, i + 1);
                        }
                      }
                    });
                  },
                  // Highlight document page with a blue border when it is being dragged
                  dragWidgetBuilder: (index, widget) {
                    return Material(
                      color: Color.fromARGB(219, 11, 185, 216),
                      borderRadius: BorderRadius.circular(20),
                      child: widget,
                    );
                  },
                  // The footer of the grid view contains an "Add New Document" button
                  // which navigates to the camera page
                  footer: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakePictureScreen(
                              existingFilename: widget.fileName,
                              newPage: numberDocuments,
                            ),
                          ),
                        );
                      },
                      child: ClayContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        borderRadius: 20,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Generate grid items for each document in the list
                  children: documents.map((doc) {
                    // Build the URL for the document's page image
                    final String imageUrl =
                        'http://192.168.178.193:3000${doc.image}';
                    return GestureDetector(
                      // Unique key to identify each document during reordering
                      key: Key(doc.id),
                      // Navigate to the document detail page when a user taps on a document item
                      onTap: () async {
                        final updatedDocuments = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Detailpage(
                                document: doc,
                                searchTerm:
                                    searchTerm), // Pass the search term for text highlighting
                          ),
                        );

                        // If the user returns from the detail page and modified the document,
                        // update the document list in the provider
                        if (updatedDocuments != null) {
                          documentProvider.setDocuments(updatedDocuments);
                        }
                      },
                      // Grid View Item Style
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ClayAnimatedContainer(
                          depth: 13,
                          spread: 5,
                          color: Color(0xFF202124),
                          borderRadius: 20,
                          curveType: CurveType.none,
                          child: Column(
                            children: [
                              // Show document page image
                              Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  child: doc.image.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.error);
                                          },
                                        )
                                      : const Icon(Icons
                                          .image_not_supported), // Fallback icon if image is not available
                                ),
                              ),
                              // Show the page number and a snippet of the document text
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text('Seite ${doc.siteNumber}',
                                        style: quicksandTextStyleSiteNumbers),
                                    SizedBox(height: 10),

                                    // If a search term is provided and it matches part of the document text,
                                    // display a highlighted snippet of the text
                                    searchTerm != "" &&
                                            doc.docText
                                                .toString()
                                                .toLowerCase()
                                                .contains(
                                                    searchTerm!.toLowerCase())
                                        ? RichText(
                                            text:
                                                getHighlightedSnippetWithHighlight(
                                              doc.docText.toString(),
                                              searchTerm!,
                                              quicksandTextStyleDocText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow
                                                .ellipsis, // Shows "..." if overflowing
                                            textAlign: TextAlign.start,
                                          )
                                        // Display normal text if no match
                                        : Text(
                                            doc.docText
                                                .join(' ')
                                                .replaceAll('\n', ' '),
                                            style: quicksandTextStyleDocText,
                                            maxLines: 1,
                                            overflow: TextOverflow
                                                .ellipsis, // Shows "..." if overflowing
                                            textAlign: TextAlign.start,
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
