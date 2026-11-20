/// Whether [candidate] is a newer release than [current].
///
/// Both are dotted numbers such as `0.1.3`, with an optional leading `v` and
/// an optional `+build` or `-pre` suffix that is ignored. Anything that does
/// not parse counts as not newer, so a odd tag can never trigger an update.
bool isNewerVersion(String current, String candidate) {
  final a = _parse(current);
  final b = _parse(candidate);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (b[i] != a[i]) return b[i] > a[i];
  }
  return false;
}

List<int>? _parse(String version) {
  final core = version
      .trim()
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp('[+-]'))
      .first;
  final parts = core.split('.');
  if (parts.length != 3) return null;
  final numbers = parts.map(int.tryParse).toList();
  if (numbers.any((n) => n == null || n < 0)) return null;
  return numbers.cast<int>();
}
