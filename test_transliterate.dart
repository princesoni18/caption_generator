import 'package:indic_transliteration_dart/indic_transliteration_dart.dart';

void main() {
  initializeSchemes();
  
  String devText = "नमस्ते, आप कैसे हैं?";
  
  print("IAST: " + transliterate(devText, fromScheme: devanagari, toScheme: iast));
  print("HK: " + transliterate(devText, fromScheme: devanagari, toScheme: hk));
  print("ITRANS: " + transliterate(devText, fromScheme: devanagari, toScheme: itrans));
  print("SLP1: " + transliterate(devText, fromScheme: devanagari, toScheme: slp1));
  print("WX: " + transliterate(devText, fromScheme: devanagari, toScheme: wx));
}
