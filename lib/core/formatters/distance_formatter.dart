class DistanceFormatter {
  DistanceFormatter._();
  static String _unit = 'km';
  static void configure({required String unit}) =>
      _unit = unit == 'mi' ? 'mi' : 'km';
  static String format(int storedKilometers) {
    final value = _unit == 'mi'
        ? storedKilometers / 1.609344
        : storedKilometers.toDouble();
    final rounded = value.round().toString();
    final parts = <String>[];
    for (var end = rounded.length; end > 0; end -= 3) {
      parts.insert(0, rounded.substring((end - 3).clamp(0, end), end));
    }
    return '${parts.join('.')} $_unit';
  }
}
