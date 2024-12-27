// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/doc_page_overview.dart';
import 'dart:io';

import '../utils/document_provider.dart';
import '../widgets/language_list.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';

import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

/// This is the [OcrProcessView] Screen, it displays the document page image and allows
/// the user to scan a text from the image using OCR (Optical Character Recognition) with the Tesseract package
///
/// Features:
/// - Selecting a language for improved scanning accuracy
/// - Extracting text from a document page image
/// - Displaying the scanned text
///
/// This screen is implemented as a stateful widget to handle dynamic interactions and updates
class OcrProcessView extends StatefulWidget {
  /// Parameters:
  /// - [takenPicture] : The current image captured with the camera.
  /// - [existingImage] : An existing image file from storage or server.
  /// - [existingFilename] : The filename of the document associated with the image.
  /// - [existingId] : The unique ID of the document page.
  /// - [existingPage] : The page number of the document.
  /// - [replaceImage] : Indicates whether the image is being replaced.
  /// - [scannedText] : Previously scanned text for the current document page, if available.
  /// - [scannedLanguage] : The language used for OCR scanning

  final String? takenPicture;
  final String? existingImage;
  final String? existingFilename;
  final String? existingId;
  final int? existingPage;
  final bool? replaceImage;
  final String? scannedText;
  final String? scannedLanguage;

  /// Constructor, which initializes optional parameters for flexibility
  const OcrProcessView(
      {super.key,
      this.takenPicture,
      this.existingImage,
      this.existingFilename,
      this.existingId,
      this.existingPage,
      this.replaceImage,
      this.scannedText,
      this.scannedLanguage});

  @override
  State<OcrProcessView> createState() => _OcrProcessViewState();
}

/// State class for the [OcrProcessView] widget.
///
/// Responsibilities:
/// - Manages state and updates related to OCR processing.
/// - Handles dynamic user interactions like scanning text and selecting languages.
/// - Updates the current document with newly scanned data and send it to the Solr server
class _OcrProcessViewState extends State<OcrProcessView> {
  // Variables to store values passed from parent screen
  late String? takenPicture;
  late String? existingFilename;
  late String? existingImage;
  late String? existingId;
  late int? existingPage;
  late bool? replaceImage;

  // Scanned text and language for OCR processing
  var showText = "";
  String selectedLanguage = "-";

  // Flags to track download, scan, and completion states
  bool isDownloading = false;
  bool isScanning = false;
  bool scanningDone = false;

  // Initialize Variables with values from the parent screen
  @override
  void initState() {
    super.initState();

    takenPicture = widget.takenPicture;
    existingImage = widget.existingImage;
    existingId = widget.existingId;
    existingPage = widget.existingPage;
    existingFilename = widget.existingFilename;
    replaceImage = widget.replaceImage;
    showText = widget.scannedText ?? "Noch kein gescannter Text.";
    selectedLanguage = widget.scannedLanguage ?? "-";
  }

  // Method to update a document page with new scanned text and send it to Solr server
  Future<void> updateDocument(String image, String id, String filename,
      String text, String language, int page) async {
    // Get a new instance of the API service for server communication
    final apiService = ApiService();

    // Format the current date and time for the document metadata
    final now = DateTime.now();
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    final finalDate = formatter.format(now);
    final finalTime = getTimeOfDate(finalDate);

    // Store the image path from captured image when uploading to server or use the existing one
    final String imagePath;

    if (takenPicture != null) {
      imagePath = await apiService.uploadImage(File(image));
    } else {
      imagePath = image;
    }

    // Send updated document data to the Solr server
    await apiService.sendDataToServer(
      filename,
      text,
      language: language,
      scanDate: finalDate,
      scanTime: finalTime,
      imageUrl: imagePath,
      id: id,
      pageNumber: page,
    );

    // Update the document list in the document provider and navigate back to the overview page
    if (mounted) {
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);
      await documentProvider.fetchDocuments();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DocumentPageOvereview(fileName: existingFilename!)),
          (route) =>
              route.isFirst, // Retain the first page for navigation history
        );
      }
    }
  }

  // Displays a modal dialog for selecting a language for OCR scanning
  void _showLanguageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF202124),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.0),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            color: Colors.transparent,
            // Child is the Language List widget
            child: LanguageList(
                currentLanguage: selectedLanguage,
                languageSelected: (newLang) {
                  setState(() {
                    selectedLanguage = newLang.langCode;
                  });
                },
                activeFilter: false),
          ),
        );
      },
    );
  }

  // Method for OCR to extract text from the provided image
  Future<void> performOCR() async {
    String? imagePath;

    // Set the flag for activated scanning processs
    setState(() {
      isScanning = true;
      scanningDone = false;
    });

    // Check if taken picture with the camera is not null and set it as image path
    if (takenPicture != null) {
      imagePath = takenPicture!;
    } else if (existingImage != null) {
      // If we have an existing image then set this as image path (it has to be downloaded)
      imagePath =
          await downloadImage('http://192.168.178.193:3000${existingImage!}');
    } else {
      setState(() {
        showText = "Kein Bild zum Extrahieren vorhanden!";
      });
      return; // Exit if no picture is available
    }

    try {
      // Perform OCR using the Tesseract OCR package with provided image and language
      String extractedText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: selectedLanguage,
      );

      // If scanning is done, set the flags and the scanned text
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = extractedText;
      });
    } catch (e) {
      // Error handling
      setState(() {
        isScanning = false;
        scanningDone = true;
        showText = "Fehler bei der OCR-Erkennung: $e";
      });
    }
  }

  // If an image already exists, we have to download it from server for OCR processing
  Future<String> downloadImage(String url) async {
    try {
      // Download the image from the url
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Save the image in a temporary directory
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/downloaded_image.jpg';
        final file = File(filePath);

        // Write the image data into a file
        await file.writeAsBytes(response.bodyBytes);

        // return a local path
        return file.path;
      } else {
        throw Exception(
            'Fehler beim Herunterladen des Bildes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Herunterladen des Bildes: $e');
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
    // Store the image url for displaying the current document page image and
    // set flags if image or id exists
    String? imageUrl;
    bool imageExists = false;
    bool idExists = false;

    // If there is an existing image, set the image URL and mark the image as existing
    if (existingImage != null && existingImage!.isNotEmpty) {
      imageUrl = 'http://192.168.178.193:3000${existingImage!}';
      imageExists = true;
    }

    // If the image should be replaced, mark the ID as existing
    if (replaceImage != null) {
      idExists = true;
    }

    // Create a widget to display the image correctly (either as a file or a network image)
    Widget customImageWidget() {
      if (takenPicture != null && existingImage == null) {
        return Image.file(File(takenPicture!),
            width: 300, height: 400, fit: BoxFit.contain);
      } else if (existingImage != null && takenPicture == null) {
        return Image.network(imageUrl!,
            errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error);
        }, width: 300, height: 400, fit: BoxFit.contain);
      } else {
        return const Icon(
            Icons.image_not_supported); // Fallback icon if no image exists
      }
    }

    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    // Define various TextStyle variables using the Quicksand font from Google Fonts
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
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
      // Creating an AppBar and icon customization
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("OCR-Verarbeitung"),
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                // Displays the document page's image within a styled container
                child: ClayContainer(
                  depth: 13,
                  spread: 5,
                  borderRadius: 20,
                  width: 300.0,
                  height: 400.0,
                  color: baseColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: customImageWidget()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                // Display two buttons in a row: one for selecting a language and another for performing OCR
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Button for opening the language list modal
                    ElevatedButton.icon(
                      onPressed: () {
                        _showLanguageDialog(context);
                      },
                      // Customized button style
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(219, 11, 185, 216),
                        elevation: 30,
                        shadowColor: Color(0xFF202124),
                        padding: EdgeInsets.all(10),
                        overlayColor: const Color.fromARGB(255, 26, 255, 114)
                            .withOpacity(0.7),
                      ),
                      icon: Icon(
                        Icons.language,
                        color: Color(0xFF202124),
                        size: 25.0,
                      ),
                      label: Text(selectedLanguage,
                          style: quicksandTextStyleButton),
                    ),
                    SizedBox(width: 20),
                    // Button for performing OCR processing (only if a language is selected)
                    ElevatedButton(
                      onPressed: () {
                        // Show a Snackbar message if no language is selected to inform the user
                        if (selectedLanguage != "-") {
                          performOCR();
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Bitte wähle eine Sprache zum Erkennen aus!'),
                                backgroundColor:
                                    const Color.fromARGB(238, 159, 29, 29),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      // Customized button style
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(219, 11, 185, 216),
                        elevation: 15,
                        padding: EdgeInsets.all(11),
                      ),
                      child:
                          Text("Text scannen", style: quicksandTextStyleButton),
                    ),
                  ],
                ),
              ),
              // Progress bar displayed while OCR text scanning is in progress
              Visibility(
                visible: isScanning,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Text('Text wird erkannt...', style: quicksandTextStyle),
                        SizedBox(height: 10),
                        ProgressIndicatorExample(),
                      ],
                    ),
                  ),
                ),
              ),
              // If text is no longer being scanned, display the container with the scanned text
              Visibility(
                visible: !isScanning,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClayContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SelectableText(
                                  showText.replaceAll('\n', ' '),
                                  textAlign: TextAlign.center,
                                  style: quicksandTextStyle),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Conditional logic for handling actions based on whether an image exists and text will be rescanned or is being replaced
                    imageExists
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Sending updated data to Solr
                                if (showText != "Noch kein gescannter Text.") {
                                  updateDocument(
                                      existingImage!,
                                      existingId!,
                                      existingFilename!,
                                      showText,
                                      selectedLanguage,
                                      existingPage!);
                                } else {
                                  if (mounted) {
                                    // Show a Snackbar if no text is available for saving
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Bitte erst das Dokument scannen!'),
                                        backgroundColor: const Color.fromARGB(
                                            238, 159, 29, 29),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              // Customized button style
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(219, 11, 185, 216),
                                elevation: 30,
                                shadowColor: Color(0xFF202124),
                                padding: EdgeInsets.all(10),
                                overlayColor:
                                    const Color.fromARGB(255, 26, 255, 114)
                                        .withOpacity(0.7),
                              ),
                              icon: Icon(
                                Icons.save,
                                color: Color(0xFF202124),
                                size: 25.0,
                              ),
                              label: Text("Speichern",
                                  style: quicksandTextStyleButton),
                            ),
                          )
                        // Handling case when an image is being replaced with a new one
                        : idExists
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Send updated data to Solr
                                    if (showText !=
                                        "Noch kein gescannter Text.") {
                                      updateDocument(
                                          takenPicture!,
                                          existingId!,
                                          existingFilename!,
                                          showText,
                                          selectedLanguage,
                                          existingPage!);
                                    } else {
                                      if (mounted) {
                                        // Show a Snackbar if no text is available for saving
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Bitte erst das Dokument scannen!'),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    238, 159, 29, 29),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  // Customized button style
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(219, 11, 185, 216),
                                    elevation: 30,
                                    shadowColor: Color(0xFF202124),
                                    padding: EdgeInsets.all(10),
                                    overlayColor:
                                        const Color.fromARGB(255, 26, 255, 114)
                                            .withOpacity(0.7),
                                  ),
                                  icon: Icon(
                                    Icons.save,
                                    color: Color(0xFF202124),
                                    size: 25.0,
                                  ),
                                  label: Text("Speichern",
                                      style: quicksandTextStyleButton),
                                ),
                              )
                            // Button for using the scanned text and passing the results to the previous page
                            : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (showText !=
                                        "Noch kein gescannter Text.") {
                                      Navigator.pop(context, {
                                        'scannedText': showText,
                                        'selectedLanguage': selectedLanguage,
                                        'isScanned': true,
                                      });
                                    } else {
                                      if (mounted) {
                                        // Show a Snackbar if no text is available for usage
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Bitte erst das Dokument scannen!'),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    238, 159, 29, 29),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  // Customized button style
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(219, 11, 185, 216),
                                    elevation: 30,
                                    shadowColor: Color(0xFF202124),
                                    padding: EdgeInsets.all(10),
                                    overlayColor:
                                        const Color.fromARGB(255, 26, 255, 114)
                                            .withOpacity(0.7),
                                  ),
                                  icon: Icon(
                                    Icons.check,
                                    color: Color(0xFF202124),
                                    size: 25.0,
                                  ),
                                  label: Text("Verwenden",
                                      style: quicksandTextStyleButton),
                                ),
                              )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
