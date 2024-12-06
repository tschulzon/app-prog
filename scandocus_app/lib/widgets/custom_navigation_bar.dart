import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );
    Color baseColor = Color(0xFFF2F2F2);
    return ClayContainer(
      color: baseColor,
      child: NavigationBar(
        backgroundColor: baseColor,
        selectedIndex: currentPageIndex,
        onDestinationSelected: onDestinationSelected,
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
    );
  }
}
