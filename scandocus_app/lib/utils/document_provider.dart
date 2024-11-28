import 'package:flutter/foundation.dart';
import '../models/document.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];

  List<Document> get documents => _documents;

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

  // Hier kannst du auch andere Methoden hinzufügen, z. B. für das Updaten der Seitenzahlen.
}
