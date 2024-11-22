import 'package:flutter/material.dart';

import '../models/document.dart';
import '../screens/ocr_page.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/camera_page.dart';

class Detailpage extends StatefulWidget {
  final Document document;
  final DocumentPage page;

  const Detailpage({super.key, required this.document, required this.page});

  @override
  State<Detailpage> createState() => _DetailpageState();
}

class _DetailpageState extends State<Detailpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seite ${widget.page.siteNumber}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.page.image,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text("Erkannter Text: "),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.page.docText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      bottomNavigationBar: BottomButtons(page: widget.page),
    );
  }
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.page});

  final DocumentPage page;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 70.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Dokument nochmal scannen',
              icon: const Icon(Icons.document_scanner),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OcrProcessView(takenPicture: page.image),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Dokument ersetzen',
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text("Seite ersetzen"),
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.camera),
                          title: Text("Foto aufnehmen"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakePictureScreen(),
                              ),
                            );
                            // Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.perm_media),
                          title: Text("Aus Galerie hochladen"),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.text_snippet),
                          title: Text("Text hinzufügen"),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Seite löschen',
              icon: const Icon(Icons.delete),
              onPressed: () {
                final SnackBar snackBar = SnackBar(
                  content: const Text('Dokument wurde gelöscht!'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {},
                  ),
                );

                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
            ),
          ),
        ],
      ),
    );
  }
}
