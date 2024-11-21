import 'package:flutter/material.dart';

import '../models/document.dart';

class Detailpage extends StatelessWidget {
  final Document document;
  final DocumentPage page;

  const Detailpage({super.key, required this.document, required this.page});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seite ${page.siteNumber}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    page.image,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text("Erkannter Text: "),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        page.docText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
