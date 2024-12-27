// Model representing a whole document with metadata for the document provider
class Document {
  final String id;
  final String fileName;
  final String scanDate;
  final String scanTime;
  int siteNumber;
  late final String language;
  final String image;
  late final List<String> docText;

  // Constructor for creating a Document instance with the required fields
  Document(
      {required this.id,
      required this.fileName,
      required this.scanDate,
      required this.scanTime,
      required this.siteNumber,
      required this.language,
      required this.image,
      required this.docText});

  // Returns a string representation of the Document object
  @override
  String toString() {
    return 'Document(fileName: $fileName, scanDate: $scanDate, scanTime: $scanTime, language: $language, siteNumber: $siteNumber, image: $image)';
  }

  // Factory method to create a Document instance from a JSON Object
  //// - [json]: A map containg key-value pairs corresponding to the Document fields
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      fileName: json['fileName'],
      scanDate:
          json['scanDate'] ?? "", // Default Value is " " if scanDate is null
      scanTime:
          json['scanTime'] ?? "", // Default Value is " " if scanTime is null
      siteNumber:
          json['siteNumber'] ?? 1, // Default Value is 1 if sitenumber is null
      language:
          json['language'] ?? "-", // Default Value is "-" if language is null
      image: json['images'] ?? "", // Default Value is " " if images is null
      docText: List<String>.from(json['docText'] ??
          []), // Default Value is an empty list if docText is null
    );
  }
}
