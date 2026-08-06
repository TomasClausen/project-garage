import 'distance_formatter.dart';

class KmFormatter {
  KmFormatter._();

  static String format(int km) {
    return DistanceFormatter.format(km);
  }
}
