import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // Für rootBundle
//import 'package:path_provider/path_provider.dart'; // Für temporäre Verzeichnisse
// import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart';

// Aktuell wird hier Flutter nur angewiesen, die in MyApp() definierte App auszuführen.
void main() {
  runApp(MyApp());
}

// Die Klasse MyApp erweitert StatelessWidget. Widgets sind Elemente, aus denen man jede Flutter-App erstellt.
// Die App selbst ist sogar ein Widget.
// Mit dem Code in MyApp wird die gesamte App eingerichtet. Damit wird der App-weite Status erstellt, der App einen Namen gegeben, das visuelle
// Design und das "Home"-Widget erstellt, also den Startpunkt der App.
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
        home: MyHomePage(), //Home Widget wird erstellt
      ),
    );
  }
}

// Die Klasse MyAppState definiert den Status der App mithilfe von ChangeNotifier
// - es definiert die Daten, die die App benötigt (Aktuell ein Zufallswortpaar)
// - Statusklasse erweitert ChangeNotifier, was bedeutet, dass sie andere über ihre eigenen Änderungen benachrichtigen kann
// z.B. wenn sich das aktuelle Wortpaar ändert, müssen einige Widgets in der App darüber informiert werden
// - Status wird erstellt und mithilfe eines ChangeNotifierProvider für die gesamte Anwendung bereitgestellt (siehe oben in MyApp)
// Dadurch kann jedes Widget in der App den Status abrufen.
class MyAppState extends ChangeNotifier {
  var current =
      WordPair.random(); //erstellt ein Zufallswortpaar als Variable bzw. Status

  var showText = "Hier wird Text angezeigt";

  File? selectedImage; // Ausgewähltes Bild als Datei

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
        language: 'eng',
      );

      // Aktualisiere den Status
      showText = extractedText;
    } catch (e) {
      showText = "Fehler bei der OCR-Erkennung: $e";
    }
    notifyListeners();
  }

  // diese Methode weist current mit einer neuen zufälligen WordPair neu zu und dazu wird notifyListeners() aufgerufen
  // notfiylisteners sorgt dafür, dass alle Zuschauer von MyAppState benachrichtigt werden
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // Wir haben der MyAppState eine neue Property namens "favorites" hinzugefügt,
  // Dieses Attribut wird mit einer leeren Liste initialisiert: []
  // Mit <WordPair>[] (generics) haben wir angegeben, dass die Liste nur Wortpaare enthalten darf.

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    print("WordPairs: $favorites");
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPages();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.favorite), label: Text('Favorites')),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BigCard(pair: pair),
        SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                print('button 1 funktioniert');
                appState.getNext();
              },
              child: Text('Next Word'),
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () async {
                print('button 1 funktioniert');
                appState.toggleFavorite();
              },
              icon: Icon(icon),
              label: Text('Like'),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                print('button 1 funktioniert');
                await appState.pickImage();
              },
              child: Text('Bild auswählen'),
            ),
            ElevatedButton(
              onPressed: () async {
                print('button 2 funktioniert');
                await appState.performOCR();
              },
              child: Text('OCR ausführen'),
            ),
            Text(
              appState.showText,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ],
    ));
  }
}

class FavoritesPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text("No favorites yet."));
    }

    var favoriteList = appState.favorites;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("You have ${appState.favorites.length} favorites: "),
        ),
        for (var favorite in favoriteList)
          // Text(favorite.asPascalCase, style: TextStyle(fontSize: 18)),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(favorite.asLowerCase),
          ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    // aktuelles Design der App mit Theme.of(context) anfordern
    final theme = Theme.of(context);

    // mit "textTheme" greift man auf das Schriftdesign der App zu, z.B. bodyMedium (Standardtext mittlerer Größe)
    // caption (für Bilduntertitel) oder headlineLarge (für große Anzeigentitel)

    // displayMedium ist ein großer Stil, der für Anzeigetext vorgesehen ist.
    // Siehe Doku: displayMedium ist für "Darstellungsstile für kurzen, wichtigen Text"
    // displayMedium! heißt ist sicher nicht null.
    // mit copyWith für displayMedium wird eine Kopie des Textstils mit den von ihnen definierten Änderungen zurückgegeben,
    // In diesem Fall ändertn wir wir nur die Textfarbe
    final style = theme.textTheme.displaySmall!.copyWith(
      // um die neue Farbe zu erhalten, muss man wieder auf das Design der APp zugreifen, die Eigenschaft "onPrimary" des Farbeschemas
      // definiert eine Farbe, die sich gut zur Verwendung der Hauptfarbe der App eignet.
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
    );

    return Card(
      // der Code definiert die Farbe der Karte so, dass sie der Farbe der colorScheme-Eigenschaft des Designs entspricht.
      // Das Farbschema enthält viele Farben, primary ist die markanteste und prägendste Farbe der App
      color: theme.colorScheme.secondary,
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
