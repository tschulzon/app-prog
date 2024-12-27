// Model representing a session for managing current pictures that are either
// taken with the camera or uploaded from the gallery
class DocumentSession {
  // A session has a current filename of the document and a list of pages included in this session
  String fileName;
  List<DocumentPage> pages = [];

  // Constructor to initialize the session with a filename
  DocumentSession({required this.fileName});

  // Method to add a page to the current session
  void addPage(DocumentPage page) {
    pages.add(page);
  }

  // Method to remove a page from the current session
  void removePage(DocumentPage page) {
    pages.remove(page);
  }
}

// Model representing a single page withing a session
// It contains all relevant information about a page
class DocumentPage {
  // A single page has those informations we need for saving it to solr server
  String imagePath;
  String scannedText;
  String captureDate;
  String language;
  int pageNumber;
  bool isScanned;

  // Constructor to initialize a single page with required and optional fields
  DocumentPage({
    required this.imagePath,
    this.scannedText = "Noch kein gescannter Text.",
    required this.captureDate,
    this.language = "-",
    required this.pageNumber,
    this.isScanned = false,
  });
}
