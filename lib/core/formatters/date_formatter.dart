class DateFormatter {
  DateFormatter._();

  static String format(String date) {
    if (date.isEmpty || date == "Sin registrar") {
      return "Sin registrar";
    }

    return date;
  }
}
