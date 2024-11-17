import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Aktuell wird hier Flutter nur angewiesen, die in MyApp() definierte App auszuführen.
void main() {
  runApp(MyApp());
}

class LangOptions {
  final String code;
  final String englishName;
  final String nativeName;

  LangOptions(
      {required this.code,
      required this.englishName,
      required this.nativeName});

  factory LangOptions.fromJson(Map<String, dynamic> json) {
    return LangOptions(
        code: json['code'],
        englishName: json['englishName'],
        nativeName: json['nativeName']);
  }
}

// Funktion, um die JSON-Datei zu laden und zu parsen
Future<List<LangOptions>> loadData() async {
  // Lade die JSON-Datei aus den Assets
  final String response = await rootBundle.loadString('assets/languages.json');

  // Die JSON-Daten dekodieren
  final Map<String, dynamic> data =
      json.decode(response); // Hier erwarten wir ein einzelnes Objekt

  // Extrahiere die Liste der Sprachen
  final List<dynamic> languagesData =
      data['languages']; // 'languages' ist der Schlüssel in deinem JSON-Objekt

  // Konvertiere die Liste von Maps in eine Liste von Language-Objekten
  return languagesData
      .map((e) => LangOptions.fromJson(e as Map<String, dynamic>))
      .toList();
}

// Funktion, um die Sprachdatei herunterzuladen
Future<void> addLanguage(String langCode) async {
  try {
    print("in AddLanguage");
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(
        'https://github.com/tesseract-ocr/tessdata/raw/main/${langCode}.traineddata'));
    HttpClientResponse response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);

    String dir = await FlutterTesseractOcr.getTessdataPath();
    File file = File('$dir/${langCode}.traineddata');

    // Die heruntergeladene Sprachdatei speichern
    await file.writeAsBytes(bytes);

    // Bestätigung
    print('$langCode wurde erfolgreich heruntergeladen und gespeichert!');
  } catch (e) {
    print('Fehler beim Hinzufügen der Sprache: $e');
  }
}

//Show downloaded Languages
Future<List<String>> getDownloadedLanguages() async {
  String tessdataPath = await FlutterTesseractOcr.getTessdataPath();
  Directory tessdataDir = Directory(tessdataPath);

  if (!tessdataDir.existsSync()) {
    return [];
  }

  // Liste aller Dateien im Verzeichnis
  List<FileSystemEntity> files = tessdataDir.listSync();

  // Filtern der Dateien, die auf ".traineddata" enden
  return files
      .whereType<File>()
      .where((file) => file.path.endsWith('.traineddata'))
      .map((file) => file.uri.pathSegments.last
          .split('.')
          .first) // Name ohne ".traineddata"
      .toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(), //App-weiter Status wird erstellt
      child: MaterialApp(
        title: 'ScanDocus', //Name wird der App gegeben
        theme: ThemeData(
            //Visuelles Design wird erstellt
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 126, 11, 137))),
        home: MainPage(), //Home Widget wird erstellt
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var showText = "Hier wird Text angezeigt";

  File? selectedImage; // Ausgewähltes Bild als Datei

  String selectedLanguage = "eng";

  // Methode zum Auswählen eines Bildes
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery); // Bild aus Galerie auswählen
      if (image != null) {
        selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      showText = "Fehler beim Bildauswählen: $e";
      notifyListeners();
    }
  }

  // Methode für die OCR-Erkennung
  Future<void> performOCR() async {
    if (selectedImage == null) {
      showText = "Bitte wähle zuerst ein Bild aus!";
      notifyListeners();
      return;
    }

    try {
      print("OCR wird ausgeführt...");
      String extractedText = await FlutterTesseractOcr.extractText(
        selectedImage!.path, // Pfad zum ausgewählten Bild
        language: selectedLanguage,
      );

      // Aktualisiere den Status
      showText = extractedText;
    } catch (e) {
      showText = "Fehler bei der OCR-Erkennung: $e";
    }
    notifyListeners();
  }

  //get the chosen language
  void setLanguage(String langCode) {
    selectedLanguage = langCode;
    notifyListeners();
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPageIndex = 0;
  String searchQuery = "";

  final List<Widget> _pages = [
    const DocumentsView(),
    const CommutePage(),
    Center(child: Text("Galerie Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Gescannte Elemente')),
        body: SingleChildScrollView(
          child: _pages[_currentPageIndex],
        ),
        bottomNavigationBar: CustomNavigationBar(
            currentPageIndex: _currentPageIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            }),
      ),
    );
  }
}

//Nur BeispielSeite für Test zum Switchen
class CommutePage extends StatelessWidget {
  const CommutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Commute Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
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
                          print("Button wurde gedrückt");
                          _showFilterDialog(context);
                        },
                        icon: const Icon(Icons.filter_alt),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const Card(
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 70,
                        height: 100,
                        child: Placeholder(),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dateiname"),
                          SizedBox(
                            height: 30,
                          ),
                          Text("Datum und Uhrzeit lol")
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
            const Divider(),
            const Card(
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 70,
                        height: 100,
                        child: Placeholder(),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dateiname"),
                          SizedBox(
                            height: 30,
                          ),
                          Text("Datum und Uhrzeit lol")
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetAnimationCurve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: 500,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dein Filter-Inhalt hier, z.B. Textfelder oder Checkboxen
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Filter-Optionen", style: TextStyle(fontSize: 16)),
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
                        // Hier könntest du den Filter anwenden, wenn ein Datum ausgewählt wurde
                        print("Datum ausgewählt: $date");
                      },
                      onDateSaved: (date) {
                        print("Datum gespeichert: $date");
                      },
                    ),
                  ],
                ),
              ),
              // Weitere Widgets für den Filter, z.B. Textfelder oder Dropdowns
              ElevatedButton(
                onPressed: () {
                  // Hier kannst du die Logik für den Filter anwenden und den Dialog schließen
                  Navigator.of(context).pop(); // Dialog schließen
                },
                child: const Text("Anwenden"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CustomNavigationBar extends StatelessWidget {
  final int currentPageIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomNavigationBar({
    super.key,
    required this.currentPageIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentPageIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.camera),
          label: 'Kamera',
        ),
        NavigationDestination(
          icon: Icon(Icons.perm_media),
          label: 'Galerie',
        ),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // Die Liste der Optionen
  late Future<List<LangOptions>> options;
  // Der aktuell ausgewählte Wert
  LangOptions? selectedOption;
  List<String> downloadedLanguages = [];
  String message = ""; //nachricht für Status Download

  @override
  void initState() {
    super.initState();
    // Lade die Daten
    options = loadData();
    loadDownloadedLanguages();
  }

  //load downloaded languages
  Future<void> loadDownloadedLanguages() async {
    List<String> downloaded = await getDownloadedLanguages();
    setState(() {
      downloadedLanguages = downloaded;
    });
  }

  //Download the Language
  void downloadLanguage() {
    if (selectedOption != null) {
      addLanguage(selectedOption!.code).then((_) {
        setState(() {
          message =
              "${selectedOption!.englishName} wurde erfolgreich heruntergeladen.";
        });
      }).catchError((error) {
        setState(() {
          message = "Fehler: $error";
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Dropdown mit Sprachdaten",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<LangOptions>>(
            future: options,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Fehler: ${snapshot.error}");
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text("Keine Optionen verfügbar.");
              } else {
                // Wenn die Daten erfolgreich geladen wurden
                List<LangOptions> data = snapshot.data!;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: DropdownButton<LangOptions>(
                            value: selectedOption,
                            hint: Text('Wähle eine Option'),
                            isExpanded: true,
                            onChanged: (LangOptions? newValue) {
                              setState(() {
                                selectedOption = newValue;
                              });

                              //set Language in AppState
                              if (newValue != null) {
                                appState.setLanguage(newValue.code);
                              }
                            },
                            items: (() {
                              List<LangOptions> sortedData = data.toList();
                              sortedData.sort((a, b) {
                                bool isADownloaded =
                                    downloadedLanguages.contains(a.code);
                                bool isBDownloaded =
                                    downloadedLanguages.contains(b.code);

                                //Manuelles Sortieren: true(heruntergeladen) kommt zuerst
                                if (isBDownloaded && !isADownloaded) return 1;
                                if (isADownloaded && !isBDownloaded) return -1;
                                return 0;
                              });
                              //Convert in DropDownMenuItem
                              return sortedData.map((LangOptions option) {
                                bool isDownloaded =
                                    downloadedLanguages.contains(option.code);

                                return DropdownMenuItem<LangOptions>(
                                  value: option,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(option.englishName),
                                      if (isDownloaded)
                                        Icon(Icons.check, color: Colors.green),
                                    ],
                                  ),
                                );
                              }).toList();
                            })(),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: downloadLanguage,
                          child: Icon(Icons.download),
                        ),
                      ],
                    ),

                    //Show message after Download
                    if (message.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(message)),
                    ElevatedButton(
                        onPressed: appState.pickImage,
                        child: Text("Bild aus Galerie wählen")),
                    if (appState.selectedImage != null)
                      Image.file(
                        appState.selectedImage!,
                      ),
                    ElevatedButton(
                      onPressed: appState.performOCR,
                      child: Text("OCR ausführen"),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          appState.showText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
