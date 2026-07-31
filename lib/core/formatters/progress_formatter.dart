class ProgressFormatter {
  ProgressFormatter._();

  static String format(double progress) {
    return "${(progress * 100).round()}%";
  }
}