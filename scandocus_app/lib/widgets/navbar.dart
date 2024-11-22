import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Erster Button
            IconButton(
              icon: Icon(
                Icons.home,
                size: 30,
                color: Colors.teal,
              ),
              onPressed: () {
                // Aktion für Dashboard
              },
            ),

            // Zweiter Button
            IconButton(
              icon: Icon(
                Icons.camera,
                size: 30,
                color: Colors.grey,
              ),
              onPressed: () {
                // Aktion für Artikel
              },
            ),

            // Dritter Button
            IconButton(
              icon: Icon(
                Icons.perm_media,
                size: 30,
                color: Colors.grey,
              ),
              onPressed: () {
                // Aktion für Einstellungen
              },
            ),
          ],
        ),
      ),
    );
  }
}
