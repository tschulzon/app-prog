// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/utils/document_provider.dart';
import 'dart:convert';

import '../models/lang_options.dart';
import '../widgets/progress_bar.dart';

/// This is the [LanguageList] widget, which displays all available languages
/// that the user can download and use from the Tesseract library
/// It is a stateful widget, meaning the widget can have states that change over time
class LanguageList extends StatefulWidget {
  final Function(LangOptions) languageSelected;
  final String currentLanguage;
  final bool activeFilter;

  LanguageList(
      {required this.languageSelected,
      required this.currentLanguage,
      required this.activeFilter});

  @override
  State<LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<LanguageList> {
  // Define TextStyle variables using the Quicksand font from Google Fonts
  final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Color.fromARGB(219, 11, 185, 216),
      fontSize: 10.0,
      fontWeight: FontWeight.w400,
    ),
  );

  final TextStyle quicksandTextStyleWhite = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 10.0,
      fontWeight: FontWeight.w400,
    ),
  );

  final TextStyle quicksandTextStyle2 = GoogleFonts.quicksand(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    ),
  );

  // Base color used for text and other elements
  Color baseColor = Color(0xFF202124);

  // Defining Variables
  String selectedLanguage = "-";
  List<String> downloadedLanguages = [];
  String message = ""; // Download Message
  bool isDownloading = false;

  // Load data and already downloaded languages when widget is initialized
  @override
  void initState() {
    super.initState();
    loadData();
    loadDownloadedLanguages();
  }

  // Load the list of languages that have already been downloaded
  Future<void> loadDownloadedLanguages() async {
    // Fetch the downloaded languages from Solr API
    List<String> downloaded = await getDownloadedLanguages();

    // Update the state with the list of downloaded languages
    setState(() {
      downloadedLanguages = downloaded;
    });
  }

  // Method to load the language data from a JSON file and parse it
  Future<List<LangOptions>> loadData() async {
    // Load the JSON file containing language options from the assets
    final String response =
        await rootBundle.loadString('assets/languages.json');

    // Decode the JSON response into a Map for easy data extraction
    final Map<String, dynamic> data = json.decode(response);

    // Extract the list of languages from the JSON object (under the 'languages' key)
    final List<dynamic> languagesData = data['languages'];

    // Convert the dynamic list into a list of LangOptions objects
    List<LangOptions> languages = languagesData
        .map((e) => LangOptions.fromJson(e as Map<String, dynamic>))
        .toList();

    // Load the list of downloaded languages for priority display
    List<String> downloaded = await getDownloadedLanguages();

    // For the language list in the filter dialog we only need to show the languages, which are used in existing documents in Solr
    if (widget.activeFilter && mounted) {
      // Retrieve all documents from provider
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);
      final fetchedDocuments = documentProvider.allDocuments;

      List<String> usedLanguages = [];

      // Loop through all documents and collect the languages used in them
      for (var doc in fetchedDocuments) {
        usedLanguages.add(doc.language);
      }

      // Filter the language list to only include languages used in the fetched documents
      languages = languages
          .where((lang) => usedLanguages.contains(lang.langCode))
          .toList();
    }

    // Sort the languages, prioritizing downloaded languages at the top
    languages.sort((a, b) {
      // Check if 'a' is downloaded and 'b' is not, 'a' comes first
      if (downloaded.contains(a.langCode) && !downloaded.contains(b.langCode)) {
        return -1;
      }

      // Check if 'b' is downloaded and 'a' is not, 'b' comes first
      if (!downloaded.contains(a.langCode) && downloaded.contains(b.langCode)) {
        return 1;
      }

      // If both languages are either downloaded or not, sort them alphabetically by name
      return a.language.compareTo(b.language);
    });

    // Return downloaded and sorted languages
    return languages;
  }

  // Method to download the selected language file
  Future<void> addLanguage(String langCode, String langName) async {
    // Set the downloading state to true
    setState(() {
      isDownloading = true;
    });

    if (isDownloading) {
      // Display the progress dialog to inform the user about the download status
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent the user from closing the dialog
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFF0F1820),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Herunterladen von $langName...',
                    style: quicksandTextStyle2),
                SizedBox(height: 20),
                ProgressIndicatorExample(), // Display progress indicator
              ],
            ),
          );
        },
      );
    }

    try {
      // Create an HTTP client to handle the download request
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          'https://github.com/tesseract-ocr/tessdata/raw/main/$langCode.traineddata')); // Request the language file

      HttpClientResponse response =
          await request.close(); // Get the response from the request
      Uint8List bytes = await consolidateHttpClientResponseBytes(
          response); // Convert the response to bytes

      // Get the path where Tesseract stores its data
      String dir = await FlutterTesseractOcr.getTessdataPath();

      // Check if the tessdata directory exists, if not create it
      Directory tessDataDir = Directory(dir);
      if (!await tessDataDir.exists()) {
        print('Creating tessdata directory...');
        await tessDataDir.create(recursive: true);
      }

      // Prepare the file path for saving the downloaded language file
      File file = File('$dir/$langCode.traineddata');

      // Write the downloaded language data to the file
      await file.writeAsBytes(bytes);

      // Set the downloading flag to false after the file is successfully saved
      isDownloading = false;

      // Close the progress dialog after downlaod is complete
      if (mounted) {
        Navigator.pop(context);
      }

      // Update the state by adding the newly downloaded language to the list
      setState(() {
        downloadedLanguages.add(langCode);
      });
    } catch (e) {
      print('Fehler beim Hinzufügen der Sprache: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // Method to get the list of the downloaded languages
  Future<List<String>> getDownloadedLanguages() async {
    // Get the path where Tesseract stores its trained data files
    String tessdataPath = await FlutterTesseractOcr.getTessdataPath();

    // Create a Directory object pointing to the tessdata directory
    Directory tessdataDir = Directory(tessdataPath);

    // Check if the tessdata directory exists, if not then return an empty list
    if (!tessdataDir.existsSync()) {
      return [];
    }

    // List of all the files inside the tessdata directory
    List<FileSystemEntity> files = tessdataDir.listSync();

    // Filter the files to include only those with the ".traineddata" extension
    // Then map each file to its name (without the ".traineddata" extension)
    return files
        .whereType<File>()
        .where((file) => file.path.endsWith('.traineddata'))
        .map((file) => file.uri.pathSegments.last.split('.').first)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Define base TextStyle with Quicksand Font from Google Fonts
    final TextStyle quicksandTextStyleLocalName = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return FutureBuilder<List<LangOptions>>(
      // Load data to build the language list asynchronously
      future: loadData(),
      builder: (context, snapshot) {
        // Show a progress indicator while data is loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Show an error message if loading fails
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        // Show a message if there are no languages available
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Keine Sprachen verfügbar.'));
        }

        // If data is loaded, display the list of languages
        List<LangOptions> languages = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: baseColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white,
                    width: 0.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Verfügbare Sprachen',
                style: GoogleFonts.quicksand(
                  textStyle: TextStyle(
                    color: Color.fromARGB(219, 11, 185, 216),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  // Check if the language is already downloaded
                  final isDownloaded =
                      downloadedLanguages.contains(lang.langCode);

                  return ListTile(
                    title: Text(lang.language,
                        style: quicksandTextStyle2), // Display language name
                    subtitle: Text(lang.localName,
                        style:
                            quicksandTextStyleLocalName), //Display local language name
                    leading: isDownloaded
                        ? Icon(Icons.check,
                            color: Color.fromARGB(219, 11, 185,
                                216)) // Show check icon if the language is downloaded
                        : IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () async {
                              // Download the language if it's not downloaded
                              await addLanguage(lang.langCode, lang.language);
                            },
                          ),
                    onTap: isDownloaded
                        ? () {
                            // Notify parent widget with the selected language
                            setState(() {
                              widget.languageSelected(lang);
                            });
                            Navigator.pop(context,
                                lang); // Close the dialog and return the selected language to parent page
                          }
                        : null, // Disable tapping for languages that are not downloaded
                    tileColor: isDownloaded
                        ? (lang.langCode == widget.currentLanguage
                            ? const Color.fromARGB(219, 15, 219, 255)
                                .withOpacity(
                                    0.1) // Highlight the selected language
                            : null)
                        : const Color.fromARGB(255, 162, 156, 162).withOpacity(
                            0.1), // Grey Color for not downloaded languages
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
