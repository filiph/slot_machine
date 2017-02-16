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

/// The final result of a slot machine session.
///
/// This encapsulates the last [Result] as well as whether or not the session
/// had any re-roll ([wasRerolled]).
class SessionResult {
  /// The final result of the roll.
  final Result result;

  /// Whether or not the user rerolled after first initial failure.
  final bool wasRerolled;

  /// Creates a RollResult with information about rerolling.
  const SessionResult(this.result, this.wasRerolled);

  /// Whether the session ended with success (but not critical success).
  bool get isSuccess => result == Result.success;

  @override
  String toString() => "SessionResult<$result,wasRerolled=$wasRerolled>";
}
