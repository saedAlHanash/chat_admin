bool isMoreThanOneMonth(int firstTimestamp, int secondTimestamp) {
  int result = (firstTimestamp - secondTimestamp).abs();

  final r = result > 2592000000;
  // if (r) loggerObject.f(r);
  return r;
}
