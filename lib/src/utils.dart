T? parseEnum<T>(String raw, List<T> enumValues) {
  for (final value in enumValues) {
    if (value.toString().split(".")[1] == raw) {
      return value;
    }
  }
  return null;
}
