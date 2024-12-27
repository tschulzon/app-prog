import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scandocus_app/screens/ocr_page.dart';
import 'package:scandocus_app/widgets/progress_bar.dart';
import 'dart:io';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/camera_page.dart';
import '../models/document_session.dart';
import '../services/api_service.dart';
import '../screens/home_page.dart';

/// This is the [DocumentOverview], where all captured images will be shown as Document Pages in a GridView
/// The user can tap on one page and will be navigated to the OCR processing Screen to scan the text
///
/// This screen is implemented as a stateful widget, meaning it can maintain and update its state
/// over its lifecycle based on user interactions or other dynamic factors.
class DocumentOverview extends StatefulWidget {
  // This screen needs a session from the parent screen, for knowing which document it is
  final DocumentSession session;
  final String? existingFilename;
  final int? newPage;

  /// Constructor, which initializes optional parameters for flexibility
  const DocumentOverview(
      {super.key, required this.session, this.existingFilename, this.newPage});

  @override
  State<DocumentOverview> createState() => _DocumentOverviewState();
}

/// State class for the [DocumentOverview] widget
/// Handles the logic for editing the filename, navigating to the pages for text scanning,
/// and saving all pages with metadata to Apache Solr Server
class _DocumentOverviewState extends State<DocumentOverview> {
  // Variables for the filename Controller and existing filenames from parent widget and new page
  // and flags for checking sending and scanned state
  late TextEditingController _fileNameController;
  late String? existingFilename;
  late int? newPage;
  bool isSending = false;
  bool isScanned = false;

  // Initializes state variables with values from parent widget
  @override
  void initState() {
    super.initState();
    // Initialize filename controller with the correct filename (existing filename or filename of current session)
    if (widget.existingFilename != null) {
      _fileNameController =
          TextEditingController(text: widget.existingFilename);
    } else {
      _fileNameController =
          TextEditingController(text: widget.session.fileName);
    }

    existingFilename = widget.existingFilename;
    newPage = widget.newPage;
  }

  // The dispose method clears all controllers when the page is closed to free up memory
  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  // Method to send documentpages with metadata to Apache Solr Server
  Future<void> sendDataToSolr() async {
    // Check if the current session contains pages. If yes, set the "sending" state to true
    if (widget.session.pages.isNotEmpty) {
      setState(() {
        isSending = true;
      });

      // Check first if all pages in the session have been scanned before sending to Solr
      bool hasScannedText = widget.session.pages
          .every((page) => page.scannedText != "Noch kein gescannter Text.");

      // If all pages are scanned show a dialog with a progress bar
      if (hasScannedText && isSending) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent the user from closing the dialog
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF0F1820),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Daten werden gespeichert...',
                    style: GoogleFonts.quicksand(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ProgressIndicatorExample(), // Progress bar to show that data is sending
                ],
              ),
            );
          },
        );

        try {
          // Create an instance of the API service to handle HTTP requests
          final apiService = ApiService();

          // Iterate through all pages in the session and upload each page's data
          for (int i = 0; i < widget.session.pages.length; i++) {
            var page = widget.session.pages[i];

            // Upload the image file to the server and get its URL
            final imagePath =
                await apiService.uploadImage(File(page.imagePath));

            // Set the correct Document Filename, if an existing name is provided, use it
            String currentFilename =
                existingFilename ?? widget.session.fileName;

            // Calculate the current page number
            int currentPage =
                existingFilename != null ? (i + 1) + newPage! : i + 1;

            // Extract the time from the page's capture date
            String documentTime = getTimeOfDate(page.captureDate);

            // Send the page's metadata and image to the Solr Server
            await apiService.sendDataToServer(
              currentFilename,
              page.scannedText,
              language: page.language,
              scanDate: page.captureDate,
              scanTime: documentTime,
              imageUrl: imagePath,
              pageNumber: currentPage,
            );
          }

          // If all data has been sent, close the progress dialog and reset the sending flag
          if (mounted) {
            setState(() {
              isSending = false;
            });
            Navigator.pop(context);
          }
        } catch (e) {
          // Handle errors during data upload
          print('Fehler beim Speichern und Senden: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Speichern und Senden der Daten'),
                backgroundColor: const Color.fromARGB(238, 159, 29, 29),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } finally {
          // Ensure the sending flag is reset to false after processing
          if (mounted) {
            setState(() {
              isSending = false;
            });
          }
        }

        // If data has been successfully sent, navigate back to the homepage where all documents are listed
        if (mounted && isSending == false) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        }
      } else {
        // If not all pages have been scanned, show a snackbar notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Es wurden noch nicht alle Texte gescanned!'),
              backgroundColor: const Color.fromARGB(238, 159, 29, 29),
              duration:
                  Duration(seconds: 3), // How long should the snackbar be shown
            ),
          );
        }
        return; // Exit the method early since not all pages are scanned
      }
    } else {
      // If there are no pages in the session, show a snackbar notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Es sind keine Seiten vorhanden!'),
          backgroundColor: const Color.fromARGB(238, 159, 29, 29),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Method to extract the time from a captured date string
  String getTimeOfDate(String date) {
    // Parse the input date string into a DateTime object
    DateTime dateTime = DateTime.parse(date);

    // Format the time as "HH:mm" like "17:15"
    String formattedTime =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    return formattedTime;
  }

  // This build method creates the widget tree for the current screen
  @override
  Widget build(BuildContext context) {
    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    // Define various TextStyle variables using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleButton = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: baseColor,
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
      ),
    );

    return Scaffold(
      backgroundColor: baseColor,
      // Creating an AppBar with title and icon customization
      appBar: AppBar(
        forceMaterialTransparency: true, // Makes the AppBar transparent
        title: Text("Dokumentübersicht"),
        titleTextStyle: GoogleFonts.quicksand(
          textStyle: TextStyle(
            color: Color.fromARGB(219, 11, 185, 216),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: baseColor,
        // Color of back button/icon
        iconTheme: const IconThemeData(
          color: Color.fromARGB(219, 11, 185, 216),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            // Neomorphism-styled container for the document name input field
            child: ClayContainer(
              color: baseColor,
              depth: 13,
              spread: 4,
              borderRadius: 20,
              child: TextField(
                style: quicksandTextStyleTitle,
                controller:
                    _fileNameController, // Filename Controller for handling user input
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      20), // Limit Filename to 20 characters
                ],
                decoration: InputDecoration(
                  labelText: "Dokumentname",
                  prefixIcon: Icon(Icons.edit,
                      color: existingFilename != null
                          ? Color.fromARGB(
                              255, 50, 51, 54) // Grey when editing is disabled
                          : Color.fromARGB(
                              219, 11, 185, 216)), // Blue when enabled
                  labelStyle: quicksandTextStyle,
                  border: InputBorder.none,
                ),
                enabled: existingFilename ==
                    null, // Enable only if filename does not exist yet
                onChanged: (value) {
                  if (existingFilename == null) {
                    // Update the session's filename dynamically as user types
                    setState(() {
                      widget.session.fileName = _fileNameController.text;
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Display document pages using a grid layout
                child: GridView.builder(
                  shrinkWrap: true,
                  physics:
                      NeverScrollableScrollPhysics(), // Disable internal scrolling
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Columns in the grid
                    crossAxisSpacing: 10.0, // Space between columns
                    mainAxisSpacing: 10.0, // Space between rows
                    mainAxisExtent: 200, // Height of each grid item
                  ),
                  itemCount: widget.session.pages.length +
                      1, // + 1 as extra slot for "Add Page"
                  itemBuilder: (context, index) {
                    if (index < widget.session.pages.length) {
                      final page = widget.session.pages[index];

                      // Display individual document pages
                      return GestureDetector(
                        onTap: () async {
                          // Navigate to the OCR processing page for this document page
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OcrProcessView(
                                takenPicture: page.imagePath,
                                scannedText: page.scannedText,
                                scannedLanguage: page.language,
                              ),
                            ),
                          );

                          // Update the document page data after returning from OCR processing
                          if (result != null && result is Map) {
                            page.scannedText = result['scannedText'] ?? "";
                            page.language = result['selectedLanguage'] ?? "-";
                            page.isScanned = result['isScanned'] ?? false;

                            // Update the UI to reflect changes
                            setState(() {
                              isScanned = true;
                            });
                          }
                        },
                        // Build the Grid Item (DocumentPage) with the image and sitenumber
                        child: ClayAnimatedContainer(
                          parentColor: page.isScanned && page.scannedText != ""
                              ? Colors
                                  .greenAccent // Green border for scanned pages
                              : baseColor, // Default background for unscanned pages
                          depth: 13,
                          spread:
                              page.isScanned && page.scannedText != "" ? 2 : 5,
                          color: baseColor,
                          borderRadius: 12,
                          curveType: CurveType.none,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 200,
                                    height: 150,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12.0),
                                            topRight: Radius.circular(12.0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            offset: Offset(0, 4),
                                            blurRadius: 4,
                                          )
                                        ]),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12.0),
                                          topRight: Radius.circular(12.0)),
                                      // Display page image
                                      child: Image.file(
                                        File(page.imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Display page number
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("Seite ${index + 1}",
                                        style: quicksandTextStyleTitle),
                                  ),
                                ],
                              ),
                              // Delete Button at the top right corner for removing a page from the session
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    // Remove the page from the current session
                                    setState(() {
                                      widget.session.removePage(
                                          widget.session.pages[index]);
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          238, 159, 29, 29),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(3),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // "Add Page" grid item for adding a new document page
                      return GestureDetector(
                        onTap: () {
                          // Navigate to the camera page to capture a new document page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TakePictureScreen(
                                session: widget.session,
                                existingFilename: widget.existingFilename,
                                newPage: newPage,
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
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      // Save and Cancel buttons in the bottom navigation bar
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Save Button for sending data to Solr Server
            ElevatedButton.icon(
              onPressed: () async {
                await sendDataToSolr();
              },
              // Customize button style
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(219, 11, 185, 216),
                elevation: 30,
                shadowColor: Color(0xFF202124),
                padding: EdgeInsets.all(10),
                overlayColor:
                    const Color.fromARGB(255, 26, 255, 114).withOpacity(0.7),
              ),
              icon: Icon(
                Icons.save,
                color: Color(0xFF202124),
                size: 25.0,
              ),
              label: Text("Speichern", style: quicksandTextStyleButton),
            ),
            SizedBox(width: 10),
            // Cancel button to discard changes and navigate back to the homepage
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              // Customize button style
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(219, 11, 185, 216),
                elevation: 30,
                shadowColor: Color(0xFF202124),
                padding: EdgeInsets.all(10),
                overlayColor:
                    const Color.fromARGB(255, 26, 255, 114).withOpacity(0.7),
              ),
              icon: Icon(
                Icons.close,
                color: Color(0xFF202124),
                size: 25.0,
              ),
              label: Text("Abbrechen", style: quicksandTextStyleButton),
            ),
          ],
        ),
      ),
    );
  }
}
