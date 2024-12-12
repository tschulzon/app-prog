import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import 'package:scandocus_app/widgets/documents_view.dart';
import 'screens/home_page.dart';
import 'utils/document_provider.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  // WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  // final cameras = await availableCameras();

  // Start der App
  runApp(
    ChangeNotifierProvider(
      create: (context) => DocumentProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  // final List<CameraDescription> cameras;

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    DocumentsView(), // Hauptseite
    TakePictureScreen(), // Kamera
    UploadImageScreen(), // Galerie
  ];

  final List<String> _titles = [
    'Dokumentenübersicht',
    'Dokument aufnehmen',
    'Aus Galerie hochladen',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);
    return MaterialApp(
      title: 'ScanDocus', //Name wird der App gegeben
      theme: ThemeData(
        //Visuelles Design wird erstellt
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: baseColor,
            indicatorColor: Color.fromARGB(219, 11, 185, 216),
            labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: GoogleFonts.quicksand().fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(219, 11, 185, 216),
            ))),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(219, 11, 185, 216),
        ),
        scaffoldBackgroundColor: baseColor,
        appBarTheme: AppBarTheme(
          backgroundColor: baseColor,
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF202124),
        appBar: AppBar(
            title: Text(
              _titles[_currentPageIndex],
              style: GoogleFonts.quicksand(
                textStyle: TextStyle(
                  color: Color.fromARGB(219, 11, 185, 216),
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            forceMaterialTransparency: true,
            centerTitle: true,
            backgroundColor: Color(0xFF202124)),
        body: _pages[_currentPageIndex],
        bottomNavigationBar: ClayContainer(
          spread: 5,
          // depth: 13,
          color: baseColor,
          child: NavigationBar(
            height: 80,
            backgroundColor: const Color(0xFF202124),
            selectedIndex: _currentPageIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.house),
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
          ),
        ),
      ),
    );
  }
}

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
