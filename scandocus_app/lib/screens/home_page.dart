import 'package:clay_containers/widgets/clay_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/documents_view.dart';
import '../screens/camera_page.dart';

/// This is the [HomePage] screen, which serves as the main entry point of the application
/// It displays the [DocumentsView] widget, where all documents are listed for easy acces
///
/// Features:
/// - Displays all documents in a list format using the [DocumentsView] widget.
/// - Provides a search bar and filter icon within the [DocumentsView] widget.
/// - Includes a bottom navigation bar, allowing the user to switch between
///   the documents view and the camera page ([TakePictureScreen])
///
/// This screen is implemented as a stateful widget to handle dynamic interactions and updates
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class for the [HomePage] widget.
/// This class manages the navigation between different pages in the bottom navigation bar
/// and updates the app bar title dynamically based on the selected page
class _HomePageState extends State<HomePage> {
  // Variable to store the current page index for the navigation bar
  int _currentPageIndex = 0;

  // List with available pages for navigation bar
  final List<Widget> _pages = [
    DocumentsView(), // Displays a list of all documents
    TakePictureScreen(), // Allows users to capture a new document using the camera
  ];

  /// List of page titles for the app bar, corresponding to each page in [_pages]
  final List<String> _titles = [
    'Dokumentenübersicht',
    'Dokument aufnehmen',
  ];

  /// Updates the current page index when the user selects a destination in the navigation bar
  /// The state is updated to trigger a UI refresh
  void _onDestinationSelected(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  // This build method creates the widget tree for the current screen
  /// It includes an app bar, the main body displaying the current page,
  /// and a custom-styled bottom navigation bar
  @override
  Widget build(BuildContext context) {
    // Base color used for text and other elements
    Color baseColor = Color(0xFF202124);

    return Scaffold(
      backgroundColor: Color(0xFF202124),
      body: Scaffold(
        backgroundColor: const Color(0xFF202124),
        // App bar with dynamic title corresponding to the selected page
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
        // Displays the currently selected page from the [_pages] list
        body: _pages[_currentPageIndex],
        // Custom-styled bottom navigation bar using the Flutter material library
        bottomNavigationBar: ClayContainer(
          spread: 5,
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
            ],
          ),
        ),
      ),
    );
  }
}
