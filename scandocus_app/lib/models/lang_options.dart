// Model representing a Language Options Object for a Language List
// This class stores information about a language, including its code, name, and download status
class LangOptions {
  final String langCode;
  final String language;
  final String localName;
  bool isDownloaded;

  // Constructor to initialize the Language Options Object with required data
  LangOptions(
      {required this.langCode,
      required this.language,
      required this.localName,
      this.isDownloaded = false}); // Is optional

  // Factory method to create a Language Option Object from a JSON Map (language.json file)
  // This is useful when parsing data received from an API or local storage
  factory LangOptions.fromJson(Map<String, dynamic> json) {
    return LangOptions(
      langCode: json['langcode'],
      language: json['language'],
      localName: json['localname'],
      isDownloaded: json['isDownloaded'] ??
          false, // Default Value is false, when no value exists
    );
  }
}
