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
      langCode: json['code'],
      language: json['englishName'],
      localName: json['nativeName'],
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }
}
