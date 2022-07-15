T? parseEnum<T>(String raw, List<T> enumValues) {
  for (final value in enumValues) {
    if (value.toString().split('.')[1] == raw) {
      return value;
    }
  }
  return null;
}

bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) {
    return false;
  }
  return a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) {
    return false;
  }
  int i = 0;
  return a.every((Object? e) => b[i++] == e);
}
