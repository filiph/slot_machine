library slot_machine.result;

/// A single result of a slot machine roll.
enum Result {
  /// Normal success.
  success,

  /// Normal failure.
  failure,

  /// Major success.
  criticalSuccess,

  /// Major failure.
  criticalFailure
}
