/// Returns a human-readable description of probability, in English.
///
/// [probability] should be between `0.0` and `1.0`, inclusive. Behavior outside
/// that range is undefined.
String humanizeProbability(num probability) {
  if (probability >= 1.0) {
    return "sure";
  }
  if (probability >= 0.8) {
    return "almost sure";
  }
  if (probability >= 0.7) {
    return "very probable";
  }
  if (probability >= 0.6) {
    return "quite likely";
  }
  if (probability >= 0.5) {
    return "quite possible";
  }
  if (probability >= 0.4) {
    return "possible";
  }
  if (probability >= 0.3) {
    return "improbable";
  }
  if (probability >= 0.2) {
    return "quite unlikely";
  }
  if (probability >= 0.1) {
    return "very unlikely";
  }
  if (probability > 0.0) {
    return "almost impossible";
  }
  return "impossible";
}
