class Document {
  final String fileName;
  final List<DocumentPage> pages;

  Document({required this.fileName, required this.pages});

  factory Document.fromJson(Map<String, dynamic> json) {
    // Umwandlung von JSON-Daten in ein Dokument-Objekt
    var pagesList = json['pages'] as List; // Liste der Seiten
    List<DocumentPage> pages = pagesList
        .map((pageJson) => DocumentPage.fromJson(pageJson))
        .toList(); // Umwandlung jeder Seite

    return Document(
      fileName: json['fileName'],
      pages: pages,
    );
  }
}

class DocumentPage {
  final String scanDate;
  final String scanTime;
  final int siteNumber;
  final String language;
  final String docText;
  final String image;

  DocumentPage({
    required this.scanDate,
    required this.scanTime,
    required this.siteNumber,
    required this.language,
    required this.docText,
    required this.image,
  });

  factory DocumentPage.fromJson(Map<String, dynamic> json) {
    // Umwandlung von JSON-Daten in ein Page-Objekt
    return DocumentPage(
      scanDate: json['scanDate'],
      scanTime: json['scanTime'],
      siteNumber: json['siteNumber'],
      language: json['language'],
      docText: json['docText'],
      image:
          json['images'] ?? '', // Default auf leer, falls kein Bild vorhanden
    );
  }
}
