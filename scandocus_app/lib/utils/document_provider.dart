import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/api_service.dart';

// A Document Provider for managing and interacting with documents in the app
// It handles fetching, filtering and updating document data
class DocumentProvider with ChangeNotifier {
  List<Document> _documents = []; // List with all existing documents
  List<Document> _filteredDocuments =
      []; // List with all filtered Documents based on active Filters
  Map<String, String?> _activeFilters = {}; // Map with currently active filters

  // Returns all documents to display
  // If filtered documents exists, it will return them
  List<Document> get documents {
    return _filteredDocuments.isNotEmpty ? _filteredDocuments : _documents;
  }

  // This returns all documents, regardless of active filter
  List<Document> get allDocuments => _documents;

  // This returns all currently active and used filter
  Map<String, String?> get activeFilters => _activeFilters;

  // Method for fetching all documents from the API service and updating the document list
  Future<void> fetchDocuments() async {
    final apiService = ApiService(); // Instance of API Service
    final newDocuments = await apiService
        .getSolrData(); // Getting all documents from Solr from the API Service with this function

    _documents = newDocuments;
    _filteredDocuments = []; // Clear the filtered Document List

    // Update all Widgets which are using the Document Provider that the state has changed (using `Provider.of<DocumentProvider>(context)`)
    // So the UI will rebuild and reflect the latest data
    notifyListeners();
  }

  // Set a new list of documents and clears the active filter
  // Notify all Widgets which are listening to the Provider
  void setDocuments(List<Document> documents) {
    _documents = documents;
    _filteredDocuments = [];
    notifyListeners();
  }

  // Removes a document from the list by its filename
  // Notify all Widgets which are listening to the Provider
  void removeDocument(String fileName) {
    _documents.removeWhere((doc) => doc.fileName == fileName);
    notifyListeners();
  }

  // Retrieving all documents which are matching a specific filename
  // Documents will be sorted by pagenumbers
  List<Document> getDocumentsByFileName(String fileName) {
    _documents.sort((a, b) => a.siteNumber.compareTo(b.siteNumber));
    return _documents.where((doc) => doc.fileName == fileName).toList();
  }

  // Applying specific filter to the documents
  // Updates the filtered Documents list and saves the used filter
  // Notify all Widgets which are listening to the Provider
  void applyFilters(List<Document> filteredDocs, Map<String, String?> filters) {
    filteredDocs.sort(
        (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    _filteredDocuments = filteredDocs;
    _activeFilters = filters;
    notifyListeners();
  }

  // Updating the document list with new search results from the Searchbar and sorts them alphabetically
  // Notify all Widgets which are listening to the Provider
  void updateSearchedDocuments(List<Document> newDocuments) {
    newDocuments.sort(
        (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    _documents = newDocuments;
    notifyListeners();
  }
}
