import 'dart:ffi';

class LangOptions {
  final String code;
  final String englishName;
  final String nativeName;
  bool isDownloaded;

  LangOptions(
      {required this.code,
      required this.englishName,
      required this.nativeName,
      this.isDownloaded = false});

  factory LangOptions.fromJson(Map<String, dynamic> json) {
    return LangOptions(
      code: json['code'],
      englishName: json['englishName'],
      nativeName: json['nativeName'],
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }
}
