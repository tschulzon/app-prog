class DocumentSession {
  String fileName;
  List<DocumentPage> pages = [];

  DocumentSession({required this.fileName});

  void addPage(DocumentPage page) {
    pages.add(page);
  }

  void removePage(DocumentPage page) {
    pages.remove(page);
  }
}

class DocumentPage {
  String imagePath;
  String scannedText;
  String captureDate;
  String language;
  int pageNumber;

  DocumentPage({
    required this.imagePath,
    this.scannedText = "",
    required this.captureDate,
    this.language = "eng",
    required this.pageNumber,
  });
}
