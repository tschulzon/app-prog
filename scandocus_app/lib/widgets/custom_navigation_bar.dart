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
