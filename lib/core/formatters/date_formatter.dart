class DateFormatter {
  DateFormatter._();

  static String _pattern = 'dd/MM/yyyy';
  static void configure({required String pattern}) => _pattern = pattern;

  static String format(String date) {
    if (date.isEmpty || date == "Sin registrar") {
      return "Sin registrar";
    }

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return _pattern == 'yyyy-MM-dd' ? '$year-$month-$day' : '$day/$month/$year';
  }
}
