import 'dart:convert'; // Für JSON-Dekodierung
import 'package:http/http.dart' as http;
import '../models/document.dart';

class ApiService {
  //IP from my computer for testing connection from physical device
  final String baseUrl = "http://192.168.178.193:3000";

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
      String? imageUrl,
      int? pageNumber}) async {
    final url =
        Uri.parse('http://192.168.178.193:3000/api/solr'); // Node.js-Server-URL

    final body = {
      'fileName': fileName,
      'docText': docText,
      'language':
          language ?? 'de', // Standardwert, wenn Sprache nicht angegeben ist
      'scanDate': scanDate ?? DateTime.now().toIso8601String(),
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
      {int start = 0, int rows = 50, String? query}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search?start=$start&rows=$rows&query=${query ?? "*:*"}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return (data['docs'] as List)
            .map((doc) => Document.fromJson(doc))
            .toList();
      } else {
        print("Fehler: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Verbindungsfehler: $e");
      return [];
    }
  }
}
