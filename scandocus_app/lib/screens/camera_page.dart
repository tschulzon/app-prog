import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scandocus_app/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import '../screens/ocr_page.dart';
import '../models/document_session.dart';
import '../screens/camera_preview_overview.dart';

/// This is the [TakePictureScreen], which allows the user to take a picture
/// using the [CunningDocumentScanner] package
///
/// The [CunningDocumentScanner] is a Flutter-based document scanner package
/// that enables capturing images of paper documents and converting them into digital files
/// It uses the ML Kit Document Scanner API and Vision Kit for edge detection and image processing
///
/// This screen is implemented as a stateful widget, meaning it can maintain and update its state
/// over its lifecycle based on user interactions or other dynamic factors.
///
/// The screen also supports additional functionalities:
/// - If a filename already exists, it can be passed through the [existingFilename] parameter
/// - Allows specifying the page number of the new image using [newPage]
/// - Enables replacing an existing image through [replaceImage]
/// - Supports managing document sessions via the [DocumentSession] object in [session]
class TakePictureScreen extends StatefulWidget {
  final String? existingFilename;
  final int? newPage;
  final bool? replaceImage;
  final String? existingId;
  final int? existingPage;
  final DocumentSession? session;

  /// Constructor, which initializes optional parameters for flexibility
  const TakePictureScreen(
      {super.key,
      this.existingFilename,
      this.newPage,
      this.replaceImage,
      this.existingId,
      this.existingPage,
      this.session});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

/// State class for the [TakePictureScreen] widget
/// Handles the core logic for capturing and managing images, including initializing
/// session details, handling camera operations, and managing loading states
class TakePictureScreenState extends State<TakePictureScreen> {
  // Represents the current document session. Default name is 'Neues Dokument'
  DocumentSession currentSession = DocumentSession(fileName: "Neues Dokument");
  List<String> _pictures = []; // New List where pictures from camera are stored
  String imagePath = ""; // Stores the path of the captured image

  // A flag to indicate whether a loading process is ongoing (e.g., camera initialization)
  bool _isLoading = false;

  // Variables to store values passed from the parent widget for modifying or replacing content
  late String? existingFilename;
  late int? newPage;
  late bool replaceImage = false;
  late String? existingId;
  late int? existingPage;
  bool morePagesWithExistingFileNames = false;

  // Initializes state variables and prepares the camera scanner for capturing images
  @override
  void initState() {
    super.initState();

    // Call platform-specific initialization, if required
    initPlatformState();

    // Generate a default file name based on the current date and time
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yy_HH-mm').format(now);
    final fileName = "Dokument_$formattedDate";

    // Initialize variables with values passed from the parent widget
    existingFilename = widget.existingFilename;
    newPage = widget.newPage;
    replaceImage = widget.replaceImage ?? false;
    existingId = widget.existingId;
    existingPage = widget.existingPage;

    // If a session is provided by the parent, use it, if not create a new session
    if (widget.session != null) {
      currentSession = widget.session!;
    } else {
      currentSession = DocumentSession(fileName: fileName);
    }

    // Check if there are more pages to add to an existing file and update the session then
    if (widget.session == null && widget.existingFilename != null) {
      morePagesWithExistingFileNames = true;
      currentSession = DocumentSession(fileName: widget.existingFilename!);
    }

    // Open the camera scanner to allow the user to capture images immediately
    openCameraScanner();
  }

  // Method for platform-specific initialization
  // Currently, this is a placeholder function for potential future platform-specific setup logic
  Future<void> initPlatformState() async {}

  /// Method to open the camera scanner and handle image capturing logic
  /// Uses the [CunningDocumentScanner] package to allow users to capture or select images
  Future<void> openCameraScanner() async {
    // Set loading state to true to show the loading indicator while the camera is initializing
    setState(() {
      _isLoading = true;
    });

    // Open the camera scanner and allow the user to take pictures
    // If replacing an image, limit the user to taking one photo, otherwise, 10 are allowed
    // The user can also import images from their gallery
    try {
      final pictures = await CunningDocumentScanner.getPictures(
            noOfPages: replaceImage == true ? 1 : 10,
            isGalleryImportAllowed: true,
          ) ??
          [];

      // If the widget is no longer mounted (i.e., context is unavailable), exit early
      if (!mounted) return;

      // Check if any pictures were captured or imported
      // If replacing an image, store the first image path and update the pictures list
      if (pictures.isNotEmpty) {
        setState(() {
          if (replaceImage == true) {
            imagePath = pictures[0];
            _pictures = pictures;
            // Otherwise, save all captured pictures to the list
          } else {
            _pictures = pictures;
          }
        });

        // Get the current date and time, formatted as 'YYYY-MM-DDTHH:mm:ss.SSSZ' as capture date from the image
        final now = DateTime.now();
        final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

        // If the user is replacing an image, then navigate to the OCR processing Screen with the captured image
        if (replaceImage == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OcrProcessView(
                  takenPicture: imagePath,
                  existingFilename: existingFilename,
                  existingId: existingId,
                  replaceImage: replaceImage,
                  existingPage: existingPage),
            ),
          );
          // If the user takes new photos for a new document then save these pictures to the current session
        } else {
          for (var picture in _pictures) {
            currentSession.addPage(DocumentPage(
              imagePath: picture,
              captureDate: formatter.format(now),
              pageNumber: currentSession.pages.length + 1,
            ));
          }

          // Navigate to the Document Overview screen to display all captured pictures
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentOverview(
                  session: currentSession,
                  existingFilename: existingFilename,
                  newPage: newPage),
            ),
          );
        }
        // Print error warning if no pictures were captured or camera opening failed
      } else {
        print("Keine Bilder aufgenommen");
      }
    } catch (exception) {
      print("Fehler beim Öffnen der Kamera: $exception");
    } finally {
      // Reset the loading state once the operation completes, regardless of success or failure
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This build method creates the widget tree for the current screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading // Check if the camera is still loading and show a circular progress indicator while the camera is initializing
              ? Center(child: CircularProgressIndicator())
              // If the camera has been closed, show options to navigate
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Text(
                          // Display a message based on whether the user can navigate back
                          Navigator.canPop(context)
                              ? "Kamera wurde geschlossen.\n\nBitte zurück zur vorherigen Seite gehen."
                              : "Kamera wurde geschlossen.\n\nBitte erneut öffnen oder wieder zur Hauptseite gehen.",
                          style: GoogleFonts.quicksand(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 50),
                      // If user can navigate back, show one button
                      Navigator.canPop(context)
                          ? ElevatedButton(
                              onPressed: () {
                                // If the user can navigate back twice, pop the current screen
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  // Otherwise, redirect to the camera page to open the camera again
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TakePictureScreen(),
                                    ),
                                  );
                                }
                              },
                              // Customize Button Style
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(219, 11, 185, 216),
                                elevation: 15,
                                overlayColor:
                                    const Color.fromARGB(255, 26, 255, 114)
                                        .withOpacity(0.7),
                              ),
                              // Button Text
                              child: Text(
                                  Navigator.canPop(context)
                                      ? "Zurück"
                                      : "Kamera öffnen",
                                  style: GoogleFonts.quicksand(
                                    textStyle: TextStyle(
                                      color: Color(0xFF202124),
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )),
                            )
                          // If the user cannot navigate back, show two buttons in a row
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Button to open the camera
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TakePictureScreen(),
                                      ),
                                    );
                                  },
                                  // Customize Button Style
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(219, 11, 185, 216),
                                    elevation: 15,
                                    padding: EdgeInsets.all(12),
                                    overlayColor:
                                        const Color.fromARGB(255, 26, 255, 114)
                                            .withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF202124),
                                    size: 30.0,
                                  ),
                                ),
                                SizedBox(width: 20),
                                // Button to navigate to the home screen
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MyApp(),
                                      ),
                                    );
                                  },
                                  // Customize Button Style
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(219, 11, 185, 216),
                                    elevation: 15,
                                    padding: EdgeInsets.all(12),
                                    overlayColor:
                                        const Color.fromARGB(255, 26, 255, 114)
                                            .withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.house,
                                    color: Color(0xFF202124),
                                    size: 30.0,
                                  ),
                                )
                              ],
                            ),
                    ],
                  ),
                ),
    );
  }
}
