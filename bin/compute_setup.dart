import 'dart:math';

import 'package:slot_machine/src/precomputed_setups.dart' show findClosest;

void main() {
  // Brute force
  final probabilities = new Map<num, List<num>>();
  for (num probabilityOfSuccessSlot = 0;
      probabilityOfSuccessSlot <= 1.0;
      probabilityOfSuccessSlot += 0.0001) {
    print("===");
    print("Creating random setup for slot probability "
        "$probabilityOfSuccessSlot.");
    final setup = createRandomSetup(probabilityOfSuccessSlot, 5, 10);

    final probSuccess = _getSuccessProbability(setup);
    if (probabilities.containsKey(probSuccess)) continue;

    probabilities[probSuccess] = getSlotLineProbabilitiesFromSetup(setup);
    print("Probability = $probSuccess");
  }

  final keys = probabilities.keys.toList();
  keys.sort();
  print(keys);

  final step = 5;
  for (int target = 0; target <= 100; target += step) {
    final closest = findClosest(target / 100, keys);
    print("${target / 100}: ${probabilities[closest]},");
  }

  print(probabilities);
}

/// Computes probabilities of success and failure depending on setup.
void computeSlotMachineProbability(List<List<bool>> setup) {
  final outcomes = _generatePossibleOutcomes(setup);

  final slotLinesCount = setup.length;

  final count = outcomes.length;
  final criticalSuccesses = outcomes.where((o) => o == slotLinesCount).length;
  final successes = outcomes.where((o) => o > 0).length;
  final failures = outcomes.where((o) => o < 0).length;
  final criticalFailures = outcomes.where((o) => o == -slotLinesCount).length;

  print("Successes:           $successes\t(${successes / count})");
  print("Failures:            $failures\t(${failures / count})");
  print(
      "Critical Successes:  $criticalSuccesses\t(${criticalSuccesses / count})");
  print(
      "Critical Failures:   $criticalFailures\t(${criticalFailures / count})");
}

/// Creates a setup in which each symbol of every slot has
/// [probabilityOfSuccessSlot] to be a success.
///
/// The setup has [slotCount] slots and each slot has [slotLinesCount] symbols.
List<List<bool>> createRandomSetup(
    num probabilityOfSuccessSlot, int slotLinesCount, int slotCount) {
  final random = new Random();
  final setup = new List<List<bool>>(slotLinesCount);
  for (int i = 0; i < slotLinesCount; i++) {
    setup[i] = new List<bool>.filled(slotCount, false);
    for (int j = 0; j < slotCount; j++) {
      setup[i][j] = random.nextDouble() < probabilityOfSuccessSlot;
    }
  }

  return setup;
}

/// Get probability of each slot of the setup.
List<num> getSlotLineProbabilitiesFromSetup(List<List<bool>> setup) {
  return new List<num>.from(setup
      .map((List<bool> line) => line.where((v) => v).length / line.length));
}

List<int> _generatePossibleOutcomes(List<List<bool>> setup,
    {int leftOffset: 0}) {
  // Compute first slot line's successes.
  final slotLinesCount = setup.length;
  final thisLineOutcomes =
      new List<int>.from(setup[leftOffset].map((b) => b ? 1 : -1));

  if (leftOffset == slotLinesCount - 1) {
    return thisLineOutcomes;
  }

  final wholeOutcomes = new List<int>();

  thisLineOutcomes.forEach((int outcome) {
    _generatePossibleOutcomes(setup, leftOffset: leftOffset + 1)
        .forEach((rightOutcome) {
      wholeOutcomes.add(outcome + rightOutcome);
    });
  });
  return wholeOutcomes;
}

num _getSuccessProbability(List<List<bool>> setup) {
  final outcomes = _generatePossibleOutcomes(setup);
  final count = outcomes.length;
  final successes = outcomes.where((o) => o > 0).length;
  return successes / count;
}
