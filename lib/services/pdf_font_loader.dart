import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  const PdfFonts({required this.regular});
  final pw.Font regular;

  pw.ThemeData get theme => pw.ThemeData.withFont(
    base: regular,
    bold: regular,
    italic: regular,
    boldItalic: regular,
  );
}

class PdfFontLoader {
  PdfFontLoader._();
  static Future<PdfFonts>? _cached;

  static Future<PdfFonts> load() => _cached ??= _load();

  static Future<PdfFonts> _load() async {
    final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return PdfFonts(regular: pw.Font.ttf(data));
  }
}
