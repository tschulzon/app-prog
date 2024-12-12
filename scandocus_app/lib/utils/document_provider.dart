import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  Map<String, String?> _activeFilters = {};

  List<Document> get documents =>
      _filteredDocuments.isNotEmpty ? _filteredDocuments : _documents;

  // Methode: Dokumente neu laden
  Future<void> fetchDocuments() async {
    final apiService = ApiService();
    final newDocuments = await apiService.getSolrData();
    _documents = newDocuments;
    notifyListeners(); // Benachrichtige alle Abonnenten
  }

  void setDocuments(List<Document> documents) {
    _documents = documents;
    _filteredDocuments = []; // Filter zurücksetzen
    notifyListeners(); // Benachrichtige alle abhängigen Widgets, dass sich der Zustand geändert hat
  }

  void addDocument(Document document) {
    _documents.add(document);
    notifyListeners();
  }

  void removeDocument(String fileName) {
    _documents.removeWhere((doc) => doc.fileName == fileName);
    notifyListeners();
  }

  List<Document> getDocumentsByFileName(String fileName) {
    return _documents.where((doc) => doc.fileName == fileName).toList();
  }

  void applyFilters(List<Document> filteredDocs, Map<String, String?> filters) {
    _filteredDocuments = filteredDocs;
    _activeFilters = filters;
    notifyListeners();
  }

  void resetFilters() {
    _filteredDocuments = [];
    _activeFilters = {};
    notifyListeners();
  }

  Map<String, String?> get activeFilters => _activeFilters;

  void updateSearchedDocuments(List<Document> newDocuments) {
    _documents = newDocuments;
    notifyListeners();
  }
}
