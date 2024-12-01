import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];

  List<Document> get documents => _documents;

  // Methode: Dokumente neu laden
  Future<void> fetchDocuments() async {
    final apiService = ApiService();
    final newDocuments = await apiService.getSolrData();
    _documents = newDocuments;
    notifyListeners(); // Benachrichtige alle Abonnenten
  }

  void setDocuments(List<Document> documents) {
    _documents = documents;
    notifyListeners(); // Benachrichtige alle abhängigen Widgets, dass sich der Zustand geändert hat
  }

  void addDocument(Document document) {
    _documents.add(document);
    notifyListeners();
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }

  List<Document> getDocumentsByFileName(String fileName) {
    return _documents.where((doc) => doc.fileName == fileName).toList();
  }

  // Hier kannst du auch andere Methoden hinzufügen, z. B. für das Updaten der Seitenzahlen.
}
