class Document {
  final String id;
  final String fileName;
  final String scanDate;
  final String scanTime;
  final int siteNumber;
  final String language;
  final String image;
  final List<String> docText;

  Document(
      {required this.id,
      required this.fileName,
      required this.scanDate,
      required this.scanTime,
      required this.siteNumber,
      required this.language,
      required this.image,
      required this.docText});

  @override
  String toString() {
    return 'Document(fileName: $fileName, scanDate: $scanDate, scanTime: $scanTime, language: $language, siteNumber: $siteNumber, image: $image)';
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      fileName: json['fileName'],
      scanDate: json['scanDate'] ?? "",
      scanTime: json['scanTime'] ?? "",
      siteNumber: json['siteNumber'] ?? 1,
      language: json['language'] ?? "eng",
      image: json['images'] ?? "",
      docText: List<String>.from(json['docText'] ?? []),
    );
  }
}
