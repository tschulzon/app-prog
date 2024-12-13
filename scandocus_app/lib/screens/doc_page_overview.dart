import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:scandocus_app/screens/camera_page.dart';
import 'package:scandocus_app/screens/doc_page.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:scandocus_app/screens/image_preview.dart';
import 'package:scandocus_app/screens/upload_page.dart';
import 'package:scandocus_app/services/api_service.dart';
import '../utils/document_provider.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/document.dart';

class DocumentPageOvereview extends StatefulWidget {
  final String fileName; // Name der Datei (optional)

  const DocumentPageOvereview({
    super.key,
    required this.fileName,
  });

  @override
  State<DocumentPageOvereview> createState() => _DocumentPageOvereviewState();
}

class _DocumentPageOvereviewState extends State<DocumentPageOvereview> {
  File? selectedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dokumente beim Betreten der Seite aktualisieren
    Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = Color(0xFF202124);
    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );

    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        final documents =
            documentProvider.getDocumentsByFileName(widget.fileName);
        // Sortieren der Dokumente nach `pageNumber`
        documents.sort((a, b) => a.siteNumber.compareTo(b.siteNumber));
        final numberDocuments = documents.length;

        return Scaffold(
          backgroundColor: baseColor,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: Text(widget.fileName),
            titleTextStyle: quicksandTextStyleTitle,
            centerTitle: true,
            backgroundColor: baseColor,
            iconTheme: const IconThemeData(
              color:
                  Color.fromARGB(219, 11, 185, 216), // Farbe des Zurück-Pfeils
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ReorderableGridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      final movedDoc = documents.removeAt(oldIndex);
                      documents.insert(newIndex, movedDoc);
                      // Prüfe, ob wir nach oben oder unten verschieben
                      if (oldIndex < newIndex) {
                        // Verschieben nach unten: Aktualisiere alle Dokumente zwischen oldIndex und newIndex (einschließlich)
                        for (int i = oldIndex; i <= newIndex; i++) {
                          ApiService().updatePageNumber(documents[i].id, i + 1);
                        }
                      } else {
                        // Verschieben nach oben: Aktualisiere alle Dokumente zwischen newIndex und oldIndex (einschließlich)
                        for (int i = newIndex; i <= oldIndex; i++) {
                          ApiService().updatePageNumber(documents[i].id, i + 1);
                        }
                      }
                    });
                  },
                  //change look from grid view item
                  dragWidgetBuilder: (index, widget) {
                    return Material(
                      color: Color.fromARGB(219, 11, 185, 216),
                      borderRadius: BorderRadius.circular(20),
                      child: widget,
                    );
                  },
                  footer: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          backgroundColor: baseColor,
                          context: context,
                          builder: (BuildContext context) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.camera),
                                  title: Text("Foto aufnehmen",
                                      style: quicksandTextStyleTitle),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TakePictureScreen(
                                          existingFilename: widget.fileName,
                                          newPage: numberDocuments + 1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.upload_file),
                                  title: Text("Aus Galerie hochladen",
                                      style: quicksandTextStyleTitle),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UploadImageScreen(
                                          existingFilename: widget.fileName,
                                          newPage: numberDocuments + 1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: ClayContainer(
                        depth: 13,
                        spread: 5,
                        color: baseColor,
                        borderRadius: 20,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ], // Hier setzen wir die Anzahl der Spalten
                  children: documents.map((doc) {
                    final String imageUrl =
                        'http://192.168.178.193:3000${doc.image}'; // Beispiel-URL
                    return GestureDetector(
                      key: Key(doc
                          .id), // Wichtiger Schlüssel, um das Element beim Umordnen zu identifizieren
                      onTap: () async {
                        // Deine Logik für das Tippen auf ein Dokument
                        final updatedDocuments = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Detailpage(document: doc),
                          ),
                        );

                        // Wenn Dokumente aktualisiert wurden, setze sie im Provider
                        if (updatedDocuments != null) {
                          // Beispiel, aktualisiere Provider mit neuen Dokumenten
                          documentProvider.setDocuments(updatedDocuments);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ClayAnimatedContainer(
                          depth: 13,
                          spread: 5,
                          color: Color(
                              0xFF202124), // Hier kannst du die Hintergrundfarbe festlegen
                          borderRadius: 20,
                          curveType: CurveType.none,
                          child: Column(
                            children: [
                              // Bild anzeigen
                              Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  child: doc.image.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.error);
                                          },
                                        )
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Seite ${doc.siteNumber}',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // body: SingleChildScrollView(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: GridView.builder(
          //       shrinkWrap: true,
          //       physics: NeverScrollableScrollPhysics(),
          //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //         crossAxisCount: 2, // 2 Spalten
          //         crossAxisSpacing: 10.0,
          //         mainAxisSpacing: 10.0,
          //         mainAxisExtent: 200,
          //       ),
          //       itemCount: documents.length + 1, // Anzahl der Seiten
          //       itemBuilder: (context, index) {
          //         if (index < documents.length) {
          //           final doc = documents[index];
          //           final String imageUrl =
          //               'http://192.168.178.193:3000${doc.image}'; //home wlan
          //           // final String imageUrl = 'http://192.168.2.171:3000${doc.image}'; //cathy wlan
          //           // final String imageUrl =
          //           //     'http://192.168.178.49:3000${doc.image}'; //eltern wlan

          //           return GestureDetector(
          //             onTap: () async {
          //               // Navigate to detail page and await the result
          //               final updatedDocuments = await Navigator.push(
          //                 context,
          //                 MaterialPageRoute(
          //                   builder: (context) => Detailpage(document: doc),
          //                 ),
          //               );

          //               // If the detail page returns updated documents, update the provider
          //               if (updatedDocuments != null) {
          //                 documentProvider.setDocuments(updatedDocuments);
          //               }
          //             },
          //             child: Padding(
          //               padding: const EdgeInsets.all(5.0),
          //               child: ClayAnimatedContainer(
          //                 depth: 13,
          //                 spread: 5,
          //                 color: baseColor,
          //                 borderRadius: 20,
          //                 curveType: CurveType.none,
          //                 child: Column(
          //                   children: [
          //                     // Bild anzeigen
          //                     Container(
          //                       width: 200,
          //                       height: 150,
          //                       decoration: BoxDecoration(
          //                           borderRadius: BorderRadius.only(
          //                               topLeft: Radius.circular(12.0),
          //                               topRight: Radius.circular(12.0)),
          //                           boxShadow: [
          //                             BoxShadow(
          //                               color: Colors.black.withOpacity(0.1),
          //                               offset: Offset(0, 4),
          //                               blurRadius: 4,
          //                             )
          //                           ]),
          //                       child: ClipRRect(
          //                         borderRadius: BorderRadius.only(
          //                             topLeft: Radius.circular(12.0),
          //                             topRight: Radius.circular(12.0)),
          //                         child: doc.image.isNotEmpty
          //                             ? Image.network(
          //                                 imageUrl,
          //                                 fit: BoxFit.cover,
          //                                 errorBuilder:
          //                                     (context, error, stackTrace) {
          //                                   // Wenn das Bild nicht geladen werden kann, zeige ein Icon oder eine Fehlermeldung
          //                                   return const Icon(Icons.error);
          //                                 },
          //                               )
          //                             : const Icon(Icons.image_not_supported),
          //                       ),
          //                     ),
          //                     Padding(
          //                       padding: const EdgeInsets.all(8.0),
          //                       child: Text('Seite ${doc.siteNumber}',
          //                           style: quicksandTextStyle),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           );
          //         } else {
          //           return GestureDetector(
          //             onTap: () {
          //               showModalBottomSheet(
          //                 backgroundColor: baseColor,
          //                 context: context,
          //                 builder: (BuildContext context) {
          //                   return Column(
          //                     children: [
          //                       ListTile(
          //                         leading: Icon(Icons.camera),
          //                         title: Text("Foto aufnehmen",
          //                             style: quicksandTextStyleTitle),
          //                         onTap: () {
          //                           Navigator.push(
          //                             context,
          //                             MaterialPageRoute(
          //                               builder: (context) => TakePictureScreen(
          //                                 existingFilename: widget.fileName,
          //                                 newPage: numberDocuments + 1,
          //                               ),
          //                             ),
          //                           );
          //                         },
          //                       ),
          //                       ListTile(
          //                         leading: Icon(Icons.upload_file),
          //                         title: Text("Aus Galerie hochladen",
          //                             style: quicksandTextStyleTitle),
          //                         onTap: () {
          //                           Navigator.push(
          //                             context,
          //                             MaterialPageRoute(
          //                               builder: (context) => UploadImageScreen(
          //                                 existingFilename: widget.fileName,
          //                                 newPage: numberDocuments + 1,
          //                               ),
          //                             ),
          //                           );
          //                         },
          //                       ),
          //                     ],
          //                   );
          //                 },
          //               );
          //             },
          //             child: ClayContainer(
          //               depth: 13,
          //               spread: 5,
          //               color: baseColor,
          //               borderRadius: 20,
          //               child: Center(
          //                 child: Icon(
          //                   Icons.add,
          //                   size: 40.0,
          //                   color: Colors.grey[600],
          //                 ),
          //               ),
          //             ),
          //           );
          //         }
          //       },
          //     ),
          //   ),
          // ),
        );
      },
    );
  }
}
