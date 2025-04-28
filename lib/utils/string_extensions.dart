extension StringCasingExtension on String {
  /// Converts `"foo bar"` or `"foo_bar"` into `"Foo Bar"`.
  String toTitleCase() {
    return replaceAll('_', ' ') // turn underscores into spaces
        .split(RegExp(r'\s+')) // split on any whitespace
        .map((word) {
          if (word.isEmpty) return word;
          final w = word.toLowerCase();
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}
