import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/document.dart';
import '../config.dart';

class ApiService {
  // Using Future<void> for making the Method asynchron
  // Method for sending documents to Solr via Node Server
  Future<void> sendDataToServer(String fileName, String docText,
      {String? language,
      String? scanDate,
      String? scanTime,
      String? imageUrl,
      int? pageNumber,
      String? id}) async {
    final url = Uri.parse('$baseUrl/api/solr');

    // Fill the body with the values from the app
    final body = {
      'id': id,
      'fileName': fileName,
      'docText': docText,
      'language': language ?? '-',
      'scanDate': scanDate ?? DateTime.now().toIso8601String(),
      'scanTime': scanTime,
      'images': imageUrl,
      'siteNumber': pageNumber,
    };

    try {
      // Send http request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Check response from server
      if (response.statusCode == 200) {
        print('Daten erfolgreich gesendet: ${response.body}');
      } else {
        print('Fehler: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

// Method for getting all documents from Solr via Node
// or also getting all documents with specific filter values
  Future<List<Document>> getSolrData(
      {int start = 0,
      int rows = 50,
      String? query,
      String? startDate,
      String? endDate,
      String? startTime,
      String? endTime,
      String? startPage,
      String? endPage,
      String? language}) async {
    try {
      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
        'start': '$start',
        'rows': '$rows',
        'query': query ?? '*:*',
        if (startDate != null && endDate != null) ...{
          'startDate': startDate,
          'endDate': endDate,
        },
        if (startTime != null && endTime != null) ...{
          'startTime': startTime,
          'endTime': endTime,
        },
        if (startPage != null && endPage != null) ...{
          'startPage': startPage,
          'endPage': endPage,
        },
        if (language != null) 'language': language,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Getting the documents and sort it after the most current scan date
        List<dynamic> documents = data['docs'];
        documents.sort((a, b) => b['scanDate'].compareTo(a['scanDate']));

        return documents.map((doc) => Document.fromJson(doc)).toList();
      } else {
        print("Fehler: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Verbindungsfehler: $e");
      return [];
    }
  }

  // Method for getting all documents with a specific search term (filename or word) the user
  // typed in the searchbar
  Future<List<Document>> searchDocuments(String searchTerm) async {
    String usedSearchTerm = searchTerm;

    // Convert the search term into double inverted commas,
    // so solr can search complete sentences and not only one word
    if (usedSearchTerm.contains(' ')) {
      usedSearchTerm = '"$searchTerm"';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/searchtext?query=$usedSearchTerm'),
    );

    if (response.statusCode == 200) {
      // Parse the response and convert it to a list
      List<dynamic> data = json.decode(response.body);
      return data.map((doc) => Document.fromJson(doc)).toList();
    } else {
      throw Exception('Fehler bei der Suchanfrage: ${response.statusCode}');
    }
  }

  // Method to upload the taken picture with the camera or the picture from the gallery
  Future<String> uploadImage(File image) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    // add the image as part of the request
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['filePath']; // Path to the saved image
    } else {
      throw Exception('Bild-Upload fehlgeschlagen: ${response.reasonPhrase}');
    }
  }

  // Method to delete more than one documentpages with the same filename
  // (When user deletes a whole document in the homepage)
  Future<void> deleteManyDocsFromSolr(String fileName) async {
    final url = Uri.parse('$baseUrl/api/deleteDocsByFileName');

    final body = {
      'fileName': fileName,
    };

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Dokument erfolgreich gelöscht ${response.body}');
      } else {
        print('Fehler: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

  // Method to delete one specific document page
  Future<void> deleteDocFromSolr(String id, String fileName) async {
    final url = Uri.parse('$baseUrl/api/deleteDocById');

    final body = {
      'id': id,
      'fileName': fileName,
    };

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Dokument-Id erfolgreich gelöscht ${response.body}');
      } else {
        print('Fehler: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

  // Method to update a page number from a specific documentpage
  Future<void> updatePageNumber(String id, int pageNumber) async {
    final url = Uri.parse('$baseUrl/api/updatepagenumber');

    // escape the id for having a correct query form for solr
    final escapedId = escapeSolrQuery(id);

    final body = {
      'id': escapedId,
      'siteNumber': pageNumber,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Update-Daten erfolgreich gesendet: ${response.body}');
      } else {
        print('Fehler: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

  // Escape special character for solr, so it can
  // search in the correct way
  String escapeSolrQuery(String query) {
    return query
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(' ', r'\ ')
        .replaceAll(':', r'\:')
        .replaceAll('-', r'\-');
  }
}
