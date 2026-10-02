const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

// "9, mai, 26", as in the prototype.
String formatTrailDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}, ${_meses[local.month - 1]}, ${(local.year % 100).toString().padLeft(2, '0')}';
}

// Kilometers without unit: one decimal below 10 km ("0.7", "5.3"), whole numbers above ("11").
String formatKm(double meters) {
  final km = meters / 1000;
  if (km >= 10) return km.round().toString();
  final text = km.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
