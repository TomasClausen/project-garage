class MoneyFormatter {
  MoneyFormatter._();

  static String _symbol = r'$';
  static String _separator = '.';

  static void configure({required String symbol, required String separator}) {
    _symbol = symbol.isEmpty ? r'$' : symbol;
    _separator = separator.isEmpty ? '.' : separator;
  }

  static String format(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(_separator);
      }
    }

    return '$_symbol$buffer';
  }
}
