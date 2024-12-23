import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  Map<String, String?> _activeFilters = {};

  // List<Document> get documents => _documents;
  List<Document> get documents {
    return _filteredDocuments.isNotEmpty ? _filteredDocuments : _documents;
  }

  List<Document> get allDocuments =>
      _documents; // Zugriff auf die ungefilterten Dokumente

  // Methode: Dokumente neu laden
  Future<void> fetchDocuments() async {
    final apiService = ApiService();
    final newDocuments = await apiService.getSolrData();

    // newDocuments.sort((a, b) => a.siteNumber.compareTo(b.siteNumber));

    _documents = newDocuments;
    _filteredDocuments =
        []; // Lösche die gefilterte Liste, damit sie wieder berechnet werden kann, wenn nötig
    notifyListeners(); // Benachrichtige alle Abonnenten
  }

  void setDocuments(List<Document> documents) {
    _documents = documents;
    _filteredDocuments = []; // Filter zurücksetzen
    notifyListeners(); // Benachrichtige alle abhängigen Widgets, dass sich der Zustand geändert hat
  }

  void removeDocument(String fileName) {
    _documents.removeWhere((doc) => doc.fileName == fileName);
    notifyListeners();
  }

  List<Document> getDocumentsByFileName(String fileName) {
    _documents.sort((a, b) => a.siteNumber.compareTo(b.siteNumber));
    return _documents.where((doc) => doc.fileName == fileName).toList();
  }

  void applyFilters(List<Document> filteredDocs, Map<String, String?> filters) {
    filteredDocs.sort(
        (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    _filteredDocuments = filteredDocs;
    _activeFilters = filters;
    notifyListeners();
  }

  Map<String, String?> get activeFilters => _activeFilters;

  void updateSearchedDocuments(List<Document> newDocuments) {
    newDocuments.sort(
        (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    _documents = newDocuments;
    notifyListeners();
  }

  void updateDocumentSiteNumber(String documentId, int newSiteNumber) {
    // Finde das Dokument anhand der ID
    final document = _documents.firstWhere((doc) => doc.id == documentId);

    // Ändere die Seitenzahl
    document.siteNumber = newSiteNumber;

    // Benachrichtige alle Abonnenten, damit die UI neu gerendert wird
    notifyListeners();
  }
}
