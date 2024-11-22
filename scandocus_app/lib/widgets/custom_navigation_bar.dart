import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0), // Abgerundete Ecken oben links
          topRight: Radius.circular(30.0), // Abgerundete Ecken oben rechts
        ),
        child: NavigationBar(
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
        ),
      ),
    );
  }
}
