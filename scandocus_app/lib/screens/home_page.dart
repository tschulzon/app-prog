import 'package:clay_containers/widgets/clay_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:scandocus_app/screens/upload_page.dart';

import '../widgets/documents_view.dart';
import '../widgets/custom_navigation_bar.dart';
import '../screens/ocr_page.dart';
import '../screens/camera_page.dart';

class HomePage extends StatefulWidget {
  // final List<CameraDescription> cameras;

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    DocumentsView(), // Hauptseite
    TakePictureScreen(), // Kamera
  ];

  final List<String> _titles = [
    'Dokumentenübersicht',
    'Dokument aufnehmen',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);

    return Scaffold(
      backgroundColor: Color(0xFF202124),
      body: Scaffold(
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
            ],
          ),
        ),
      ),
    );
  }
}
