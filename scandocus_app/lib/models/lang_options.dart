class LangOptions {
  final String langCode;
  final String language;
  final String localName;
  bool isDownloaded;

  LangOptions(
      {required this.langCode,
      required this.language,
      required this.localName,
      this.isDownloaded = false});

  factory LangOptions.fromJson(Map<String, dynamic> json) {
    return LangOptions(
      langCode: json['langcode'],
      language: json['language'],
      localName: json['localname'],
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }
}
