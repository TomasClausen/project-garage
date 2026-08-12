import 'dart:math';

class IdGenerator {
  static String generate() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(999).toString();
  }

  static String prefixed(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
}
