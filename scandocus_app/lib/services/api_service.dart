import 'dart:convert'; // Für JSON-Dekodierung
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/document.dart';

class ApiService {
  //IP from my computer for testing connection from physical device
  final String baseUrl = "http://192.168.178.193:3000";
  // final String baseUrl = "http://192.168.2.171:3000";
  // final String baseUrl = 'http://192.168.178.49:3000'; //eltern wlan

  Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/test'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Server-Antwort: ${data['message']}");
      } else {
        print("Fehler: ${response.statusCode}");
      }
    } catch (e) {
      print("Verbindungsfehler: $e");
    }
  }

  // Future<void>, um die Funktion asynchron zu gestalten
  Future<void> sendDataToServer(String fileName, String docText,
      {String? language,
      String? scanDate,
      String? scanTime,
      String? imageUrl,
      int? pageNumber,
      String? id}) async {
    final url =
        Uri.parse('http://192.168.178.193:3000/api/solr'); // Node.js-Server-URL
    // final url = Uri.parse('http://192.168.2.171:3000/api/solr');
    // final url = Uri.parse('http://192.168.178.49:3000/api/solr');

    final body = {
      'id': id,
      'fileName': fileName,
      'docText': docText,
      'language':
          language ?? 'de', // Standardwert, wenn Sprache nicht angegeben ist
      'scanDate': scanDate ?? DateTime.now().toIso8601String(),
      'scanTime': scanTime,
      'images': imageUrl,
      'siteNumber': pageNumber,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Daten erfolgreich gesendet: ${response.body}');
      } else {
        print('Fehler: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

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

      print("URL:");
      print(uri);

      final response = await http.get(uri);

      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> documents = data['docs'];
        print("THIS ARE DOCUMENTS");
        print(documents);
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

  Future<List<Document>> searchDocuments(String searchTerm) async {
    String usedSearchTerm = searchTerm;

    if (usedSearchTerm.contains(' ')) {
      usedSearchTerm =
          '"$searchTerm"'; // In doppelte Anführungszeichen setzen um ganze Sätze suchen zu können
    }

    print("USED TERM");
    print(usedSearchTerm);

    final response = await http.get(
      Uri.parse(
          'http://192.168.178.193:3000/searchtext?query=$usedSearchTerm'), // Node.js-Serveradresse anpassen
    );

    print("RESPONSE");
    print(response);

    if (response.statusCode == 200) {
      // Antwort parsen und in eine Liste von Dokumenten umwandeln
      List<dynamic> data = json.decode(response.body);
      return data.map((doc) => Document.fromJson(doc)).toList();
    } else {
      throw Exception('Fehler bei der Suchanfrage: ${response.statusCode}');
    }
  }

  Future<String> uploadImage(File image) async {
    final uri = Uri.parse('http://192.168.178.193:3000/upload');
    // final uri = Uri.parse('http://192.168.2.171:3000/upload');
    // final uri = Uri.parse('http://192.168.178.49:3000/upload');
    final request = http.MultipartRequest('POST', uri);

    // Bild als Teil der Anfrage hinzufügen
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    // Anfrage absenden
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['filePath']; // Pfad zum gespeicherten Bild
    } else {
      throw Exception('Bild-Upload fehlgeschlagen: ${response.reasonPhrase}');
    }
  }

  // Future<void>, um die Funktion asynchron zu gestalten
  Future<void> deleteManyDocsFromSolr(String fileName) async {
    final url = Uri.parse(
        'http://192.168.178.193:3000/api/deleteDocsByFileName'); // Node.js-Server-URL
    // final url = Uri.parse('http://192.168.2.171:3000/api/deleteDocsByFileName');
    // final url =
    //     Uri.parse('http://192.168.178.49:3000/api/deleteDocsByFileName');

    final body = {
      'fileName': fileName,
    };

    try {
      // HTTP-DELETE-Anfrage senden
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Überprüfen der Antwort vom Server
      if (response.statusCode == 200) {
        print('Dokument erfolgreich gelöscht ${response.body}');
      } else {
        print('Fehler: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

  Future<void> deleteDocFromSolr(String id, String fileName) async {
    final url = Uri.parse(
        'http://192.168.178.193:3000/api/deleteDocById'); // Node.js-Server-URL
    // final url = Uri.parse('http://192.168.2.171:3000/api/deleteDocById');
    // final url = Uri.parse('http://192.168.178.49:3000/api/deleteDocById');

    final body = {
      'id': id,
      'fileName': fileName,
    };

    try {
      // HTTP-DELETE-Anfrage senden
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Überprüfen der Antwort vom Server
      if (response.statusCode == 200) {
        print('Dokument-Id erfolgreich gelöscht ${response.body}');
      } else {
        print('Fehler: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fehler beim Senden der Anfrage: $e');
    }
  }

  // API-Aufruf, um nur die Seitenzahl zu aktualisieren
  Future<void> updatePageNumber(String id, int pageNumber) async {
    final url = Uri.parse(
        'http://192.168.178.193:3000/api/updatepagenumber'); // Node.js-Server-URL
    // final url = Uri.parse('http://192.168.2.171:3000/api/solr');
    // final url = Uri.parse('http://192.168.178.49:3000/api/solr');

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

  String escapeSolrQuery(String query) {
    return query
        .replaceAll(r'\', r'\\') // Backslashes escapen
        .replaceAll('"', r'\"') // Anführungszeichen escapen
        .replaceAll(' ', r'\ ') // Leerzeichen escapen
        .replaceAll(':', r'\:') // Doppelpunkte escapen
        .replaceAll('-', r'\-'); // Minus escapen
  }
}
